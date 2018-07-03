% create and transfer BUFR files to CMSS and to textfiles backup
if dbdat.maker==3

	outcome = write_BUFR(dbdat,float(np+1));
else
	outcome = write_BUFR(dbdat,float(np));
end
