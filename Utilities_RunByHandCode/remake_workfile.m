function remake_workfile(wm,pn)


for jj = pn
   fnm = find_argos_download(wm,jj);
   if isempty(strmatch(fnm,'NOTFOUND'))
      npro = strip_for_workfile(fnm,wm,jj);
      if ~npro
	 disp(['*** FAILED to remake ' num2str([wm jj])]);
      end
   else
      disp(['*** REMAKE WORKFILE: no download found for ' num2str([wm jj])]);
   end
end


