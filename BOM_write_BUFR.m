% create and transfer BUFR files to CMSS and to textfiles backup
if dbdat.maker==3

	write_BUFR(dbdat,float(np+1))
else
	write_BUFR(dbdat,float(np))
end
