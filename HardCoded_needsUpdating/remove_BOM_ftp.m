%remove_BOM_ftp

    if(exist('/home/ftp/incoming/bom_ftp_done','file'))
        bom_file_exists=1
        system(['mv -f /home/ftp/pub/gronell/iridium_data/*.* /home/ftp/pub/gronell/hold_iridium_data_sent'])
        system(['rm /home/ftp/incoming/bom_ftp_done'])
        files_deleted=1
        
    end
