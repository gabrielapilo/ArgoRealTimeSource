#-------------------------------------------------------------------------------------------------------------------------
#
# Title:                emails2files.py
# One line description: using a driver file as input it reads emails/attachments (those for  a given subject, copies to files  
#				and moves emails thereafter
# Author:               Lise Quesnel
# Date:			04 Aug 2016 - version 1.0
# Date:                 09 Aug 2016 - version 1.1
# Date:                 30 Nov 2016 - version 1.2 (Matt Donnelly)
#
#
# Design of script: 	the modules are defined at the top of this file where the aim is to not put specific business logic in the
#			modules: only logic related to its dedicated task; let the 'main' decide what to do with output or error	
#			
#			the 'main' module is where the business logic is added; this enables us to add/remove modules in the future
#			with the aim of reducing modifications to existing logic and thus reducing the introduction of bugs
#
#			this is a generic script so any input should not be hard-coded but passed on from the driver file
#
#			due to the simplicity of the the error handling approach at time of writing is to assume that an error should
#			stop the workflow because it's an integrity issue for all emails - hence 'raise Base Exception' is used
#
#			Note: The emails that are extracted become 'read'  (it is possible to keep them 'unread' - add a different module!)
#
#			Note: the following syntax is chosen on purpose to get a persistent unique id: c.uid('FETCH', email_uid, '(RFC822)')
#								rather than c.fetch  or c.search
#
#				however, if the same email is copied/moved manually e.g. to original folder, it will now have a different identifier
#
#			Note: sometimes the python packages raise an exception if there is an error as well as not a status of 'OK', sometimes
#				it's just not a status of 'OK' - due to limited resources, we simply tried to cover both possibilities
#	
#			Note: the decision was made to accept that if an exception occurs after some emails were processed, there is no rollback
#				this is deemed ok because if the script is run again, it will finish the remaining ones 
#				RISK: should the error have occured prior to the 'move', the email remains behind and is re-processed but the
#					files are not re-created since they already exist (assuming the unique identifier is used)
#
#			See detailed comments in the 'createheaderfile' module
#
# INDENTATION IS CRITICAL
# Python requires indentation to know start and end of sequential lines; it's not the number of spaces but alignment of the start of each line
#		  WARNING at first, it's easy to get it wrong and lines get executed when they shouldn't!
#
# Mods: 1.0 - created
#	1.1 - using filename and not Content-Disposition to distinguish attachments from headers as some
#		emails have their text as 'inline' Content-Disposition though with no filename
#       1.2 - added character replacement for ':' to '_' to provide support to Windows file systems
#           - added module for raw email scrape
#	    - modification to correct operation of module
#
import sys,imaplib, ConfigParser, os, base64, email, logging, logging.handlers, email.header, datetime

#### 
# simply to simplify checking if a variable is not empty before we try to use it
####
def is_not_empty(any_structure):
    if any_structure:
        #print('Structure is not empty.')
        return True
    else:
        #print('Structure is empty.')
        return False
####
# set up the logfile where the name is set in the driver file
####
def getlogfilevar(logfilename):

	LOG_FILENAME = logfilename

	# Set up a specific logger with our desired output level
	my_logger = logging.getLogger('MyLogger')
	my_logger.setLevel(logging.DEBUG)

        # Add the log message handler to the logger
        handler = logging.handlers.RotatingFileHandler(
              LOG_FILENAME, maxBytes=500000, backupCount=5)
	# create formatter
        formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
	handler.setFormatter(formatter)
	my_logger.addHandler(handler)

	return my_logger

####
# open the connection to email server
####
def open_connection(verbose,hostname,my_log):

        # Connect to the server
        if verbose: my_log.debug('Connecting to ' + hostname)
        connection = imaplib.IMAP4_SSL(hostname)

        # Login to our account
        addr = config.get('account', 'addr')
        val = base64.b64decode(config.get('account', 'val'))
        if verbose: my_log.debug('Logging in as ' + addr)
        loginstatus, cd = connection.login(addr, val)
	if loginstatus == 'OK':
		my_log.debug('Login status: ' + loginstatus)
	else:
	        my_log.debug('No exception thrown by library but Login status is : '+loginstatus+'  so stopping workflow')
		raise BaseException
        return connection

####
# get the structure holding the information for the given directory
####
def get_mailbox_info(verbose,mbname,conn,mylog):

	# attempt to get info instance
	liststatus, data = conn.list(directory=mbname)
	if liststatus == 'OK':
		my_log.debug('Obtained info for mailbox: ' + mbname)
	else:
		my_log.debug('Was trying to obtain info for mailbox: ' + mbname + ' but status is: '+liststatus+' creating an exception to stop workflow')
		raise BaseException
	return data

####
# get the list of unique identifiers from the given directory as per given subject
####
def get_identifiersbysubject(verbose,filterwith,conn,my_log):

	# attempt to get identifiers
	uidsstatus, uids = conn.uid('SEARCH', None, '(SUBJECT "'+filterwith+'")')
	if uidsstatus == 'OK':
		if  is_not_empty(uids[0]):
			# despite uids being a list  - try str(type(uids)), the length is always 1
			#total = str(len(uids))
			# for now, counting spaces
			total = str(uids[0].count(' ') + 1)
		else:
			total = '0'
                my_log.debug('Obtained '+total+' unique identifiers for filter subject with: ' + filterwith)
        else:
                my_log.debug('Was trying to obtain identifiers for filter subject with: ' + filterwith + ' but status is: '+uidsstatus+' creating an exception to stop workflow')
                raise BaseException
        return uids

####
# create a file for the header information
####
def createheaderfileusingsubject(verbose,path,email_uid,c,my_log):

#
# NB: any new emails should be tested as per usual Software Development Lifecycle in case our interpretation is too limited
#
# NB: MIME messages are not necessarily consistent across implementations; this could break for more complicated
#       mail properties
#
# The approach here uses the 'email package' which sits on top of 'imap': https://docs.python.org/2/library/email.message.html
#
# Since we are interested in only three parts at this point in time: (1) subject, (2)  text we 'see' in the email and (3) all attachments,
# the following steps are taken:
#	- to allow for a variety of 'content type's, the code below does not search on headers but rather loops through all parts
#	- despite example on 'web', we cannot use Content-Disposition to filter out attachments because we have use cases where
#		Content-Disposition is 'inline' BUT there is no file name
#	- consequently, we filter on filename: if none, we assume 'header' info and concatenate all found
#		                               if filename found, we assume attachment and use it as filename with prefix
#	- to get all parts, the email is 'flattened' via message_from_string (to see it uncomment hdrmail)
#	- as per above URL, there are two parts: 
#			headers or key : value pairs  (e.g. MIME-Version: 1.0)
#			payload: which appears to be 'the rest' in a segment that ends with a line starting with two hyphens 
#							e.g. --_002_357C0FB37792B7469A9056E9F8A2269B3B8013CCsose0027gmarlab_--
#
#
# 
	header = None
	newfileName = None
	combinedheader = ''
	hdrfetchstatus, hdrdata = c.uid('FETCH', email_uid, '(RFC822)')
	if hdrfetchstatus == 'OK':
		hdrmail = email.message_from_string(hdrdata[0][1])
	 	#print hdrmail
		# get the subject right away; if no subject; a new module would be needed as this one filters on subject!
		decode = email.header.decode_header(hdrmail['Subject'])[0]
		if decode is not None or decode !='':
			subject = unicode(decode[0])
			my_log.debug('subject is: ' + subject)
			newsubject = subject.replace(' ','_')
                        newsubject2  = newsubject.replace(':','_')
			# add uid as prefix to link it to header file
			newfileName = email_uid+ '_' + newsubject2
		for part in hdrmail.walk():
                        if part.get_filename() is not None:
                        	continue
                        header = part.get_payload(decode=True)
                        if header is None:
                                my_log.debug('payload is None when trying to get the header; skipping to next "part" of email ')
                                continue
			#my_log.debug('header 1a:' + header)
			if header is not None:
				combinedheader = ''.join([combinedheader,header])
	else:
                my_log.debug('Was trying to fetch header for uid : ' + email_uid + ' but status is: '+hdrfetchstatus+' cannot create header file')

# now that we've looped through all the parts of the email
# create the file
	if newfileName is None and combinedheader is not None:
		newfileName =  email_uid+ '_no_subject_found'
	if is_not_empty(newfileName) and combinedheader is not None:
		# only create if it does not exist
                if bool(newfileName):
                        filePath = os.path.join(path, newfileName)
                        if not os.path.isfile(filePath) :
                                my_log.debug('saving: ' + newfileName)
                                fp = open(filePath, 'w')
                                fp.write(combinedheader)
                                fp.close()
	else:
		my_log.debug('Was trying to fetch header for uid : ' + email_uid + ' but no header at this late point; cannot create header file')

####
# create file for (one per) attachment
####
def createattachfiles(verbose,path,email_uid,c,my_log):

# NB: see comments in createheader file
# 
        fetchstatus, data = c.uid('FETCH', email_uid, '(BODY[])')
        if fetchstatus == 'OK':
                mail = email.message_from_string(data[0][1])
                # this handles more than one attachment; each is a 'part'
                for part in mail.walk():
                        if part.get_content_maintype() == 'multipart':
                                continue
                        if part.get_filename() is None:
                                continue
	                fileName = part.get_filename()

        	        # add uid as prefix to link it to header file
                        newfileName = email_uid +'_' + fileName

	                # only create if it does not exist
        	        if bool(newfileName):
				filePath = os.path.join(path, newfileName)
				if not os.path.isfile(filePath) :
					my_log.debug('saving: ' + newfileName)
					fp = open(filePath, 'wb')# b because we don't know if text or not (to be reviewed as for Windows)
					fp.write(part.get_payload(decode=True))
					fp.close()

        else:
                my_log.debug('Was trying to fetch attachments for uid : ' + email_uid + ' but status is: '+fetchstatus+' creating an exception to stop workflow')
                raise BaseException

####
# create file for an email scrape
####
def createemailscrape(verbose,path,email_uid,c,my_log):

# NB: see comments in createheader file
# 
        fetchstatus, data = c.uid('FETCH', email_uid, '(RFC822)')
        if fetchstatus == 'OK':
		
                body = data [0][1] # raw text of entire email
				
		addr = config.get('account','addr')
		domain = config.get('account','domain')
		user_savename = addr.rstrip(domain)
                newfileName = user_savename+"-"+email_uid+".txt"
     
	        # only create if it does not exist
                if bool(newfileName):
			filePath = os.path.join(path, newfileName)
			if not os.path.isfile(filePath) :
				my_log.debug('saving: ' + newfileName)
				fp = open(filePath, 'wb')# b because we don't know if text or not (to be reviewed as for Windows)
				fp.write(body)
				fp.close()

        else:
                my_log.debug('Was trying to fetch email scrape for uid : ' + email_uid + ' but status is: '+fetchstatus+' creating an exception to stop workflow')
                raise BaseException
				
####
# move the email to a new directory (no actual 'move' implemented in imap: copy then delete)
####
def copydelemail(verbose,tofolder,email_uid,c,my_log):

        copystatus = c.uid('COPY', email_uid, tofolder)
        if copystatus[0] == 'OK':
                delstatus, data = c.uid('STORE', email_uid , '+FLAGS', '(\Deleted)')
                if delstatus == 'OK':
                        c.expunge()
                else:
                        my_log.debug('Was trying to delete email (have to copy then delete) for uid : ' + email_uid +
				 ' but status is: '+delstatus[0]+' creating an exception to stop workflow')
                	raise BaseException
        else:
                my_log.debug('Was trying to copy email (have to copy then delete) for uid : ' + email_uid + 
				' but status is: '+copystatus[0]+' creating an exception to stop workflow')
                raise BaseException


##########################################################################
#
#          Main workflow
#
##########################################################################
#
if __name__ == '__main__':

	#imaplib.Debug = 4
	verbose = True

	# get name of configuration file (driver file) (script itself is in position 1, hence < 2)
	if len(sys.argv) < 2 or not is_not_empty(sys.argv[1]):
		print '!!!!!! ** Need a configuration as an input when calling this script ****'
                raise BaseException

	# create variable for config info
	config = ConfigParser.ConfigParser()
        config.read([os.path.expanduser(sys.argv[1])])

        # Get log file up and running
        my_log = getlogfilevar(config.get('logfile', 'name'))
	my_log.debug('')
	my_log.debug('****************')
	my_log.debug('')
	my_log.debug('Starting new instance of emails2files.py using its config file')
	
	#############################
	# open connection ###########
        try:
		c = open_connection(verbose,config.get('server', 'hostname'),my_log)
	except:
		my_log.exception('Exception occurred while trying to connext to host; exiting at this point to inform')
		try:
	                c.logout()
		except NameError:
			my_log.debug('host connection never got created or never returned to main so could not close it')
		# is part of previous 'except' hence the indent
		raise BaseException

	###############################
	# get mailbox info ############
	try:
		mbinfo = get_mailbox_info(verbose,config.get('server', 'readfromfolder'),c,my_log)
		# nb: at this time, mbinfo variable is not used yet but needed to have connection pointing to this mailbox
		# 	for getting identifiers later (unless I've misunderstood)

		# if a maximum is given use it to test - purposely not putting in function since this is business logic
		cannotcontinue = False
		try:
			maxcount = config.get('server', 'expectedmaxcount')
			selectstatus,count = c.select(config.get('server', 'readfromfolder'))
			if selectstatus == 'OK':
				if int(count[0]) > int(maxcount):
					my_log.debug('Suspiciously high count ('+str(count[0])+' )of emails (beyond max given) in '+
						config.get('server', 'readfromfolder')+'; exiting at this point to inform')
	                                cannotcontinue = True
				else:
					my_log.debug('Found ' + str(count[0]) + ' emails')
			else:
				my_log.debug('Could not get count of emails status is '+selectstatus+'; exiting at this point to inform')
				cannotcontinue = True
		except:
			my_log.debug('no maximum number of email specified: at risk!')
		# if no config, we just continue since optional check
		if cannotcontinue:
			raise BaseException
		
	except:
                my_log.exception('Exception or expected error (see log) occurred while trying to get mailbox info; exiting at this point to inform')
                try:
                        c.logout()
                except NameError:
                        my_log.debug('host connection never got created or never returned to main so could not close it')
		# is part of previous 'except' hence the indent
		raise BaseException

	##################################
	# get unique identifiers ######### (uids not the temporary identifiers that change, hence use of .uid and not c.search)
	try:
		# at time of writing, only one filter written; write new one and add info in config file if necessary
		try:
			filterby = config.get('server', 'filterby')
			test2 = config.get('server', 'filterwith')
		except:
			my_log.debug('expected filterby subject and a value since only use case so far; exiting at this point to inform')
			# not an optional config at this point so exiting
			raise BaseException
		if filterby == 'subject':
			uids = get_identifiersbysubject(verbose,config.get('server', 'filterwith'),c,my_log)	
		else:
			my_log.debug('expected filterby = subject; no other use case supported yet')
			raise BaseException
	except:
		my_log.exception('Exception occurred while trying to get unique identifiers (uids); exiting at this point to inform')
                try:
                        c.logout()
                except NameError:
                        my_log.debug('host connection never got created or never returned to main so could not close it')
		# is part of previous 'except' hence the indent
                raise BaseException

        ###############################
        # process one identifier
        #
        #  - if in config, create header file with uid then subject (spaces replaced) as prefix
        #  - if in config, create a file per attachment with uid as prefix
        #  - if in config, 'move' email to new folder
        #
        #  TBC note: at time of writing, the filenames of the attachments are listed in the header file to link the two
        #
        #  vs TBC - list attachments in header file but then we have to parse it to link it     
        #               using the uid as prefix keeps them together but it can also be easily stripped out
        #

        #
        # purposefully putting the loop (business logic) in the main to keep the modules for processing a single uid
        #
        # Determine which file types to create and if move email 
        try:
                createheader = False
                createattach  = False
		createscrape = False
		copydelmail = False
                # check if create header file
                try:
                        saveheader = config.get('linux', 'saveheader')
                        savepathhdr = config.get('linux', 'savepathhdr')
                        if is_not_empty(saveheader) and saveheader == 'yes' and is_not_empty(savepathhdr):
                                createheader = True
                except:
                        my_log.debug('not saving header as per config (that is, missing saveheader and/or savepath input or not yes)')

                try:
                        saveattach = config.get('linux', 'saveattachments')
                        savepathatt = config.get('linux', 'savepathatt')
                        if is_not_empty(saveattach) and saveattach == 'yes' and is_not_empty(savepathatt):
                                createattach = True
                except:
                        my_log.debug('not saving attachments as per config (that is, missing saveattachments and/or savepath input or not yes)')

		try:
                        saveemailscrape = config.get('linux', 'saveemailscrape')
                        savepathscrape = config.get('linux', 'savepathscrape')
                        if is_not_empty(saveemailscrape) and saveemailscrape == 'yes' and is_not_empty(savepathscrape):
                                createscrape = True
                except:
                        my_log.debug('not saving eail scrape as per config (that is, missing saveemailscrape and/or savepath input or not yes)')
						
                try:
                        moveemail = config.get('server', 'moveemail')
                        movetofolder = config.get('server','movetofolder')
                        if is_not_empty(moveemail) and moveemail == 'yes' and  is_not_empty(movetofolder):
                                copydelmail = True
                except:
                        my_log.debug('not moving emails as per config (that is, missing moveemail and/or movefolder input or not yes)')

                for email_uid in uids[0].split():
                        if createheader:
                                createheaderfileusingsubject(verbose,savepathhdr,email_uid,c,my_log)
                        if createattach:
                                createattachfiles(verbose,savepathatt,email_uid,c,my_log)
			if createemailscrape:
                                createemailscrape(verbose,savepathscrape,email_uid,c,my_log)		
                        if copydelmail:
                                copydelemail(verbose,movetofolder,email_uid,c,my_log)
        except:
                my_log.exception('Exception occurred while trying to create or copy/delete file(s) see error messages; exiting at this point to inform')
                try:
                        c.logout()
                except NameError:
                        my_log.debug('host connection never got created or never returned to main so could not close it')
			# is part of previous 'except' hence the indent
			raise BaseException


	# logout connection if got this far with no early exiting
	try:
		c.logout()
	except:
		pass
	my_log.debug('Ended successfully in that no errors were detected')
