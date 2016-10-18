function[list]=dirc(dir_name,filter,sort_by,group)

%DIRC Directory listing with cell output and optional arguments.
%
%  DIRC(DIR_NAME) uses the DIR function to return the directory listing of
%  directory DIR_NAME, with usage of optional arguments, and with the
%  following differences in output:
%
%    - The output is in a 'cell' format instead of a 'structure' format.
%
%    - The output includes the following columns (in the stated order):
%        Full Item Name, Item Name, Item Extension, Date, Bytes, IsDir
%
%  OPTIONAL ARGUMENTS:
%
%    The following are arguments that can optionally be used:
%
%    (If the value for any of the arguments below is left blank, i.e. if it
%    is entered as '', the stated default value is used.)
%
%    FILTER:
%      a:  Return all items (both files and directories) (default).
%      ae: Return all items (both files and directories), but excludes the
%          '.' and '..' directories if they are present.
%      f:  Return only files.
%      d:  Return only directories.
%      de: Return only directories, and excludes the '.' and '..'
%          directories if they are present.
%
%    SORT_BY:
%      o: Use original DIR function's dictionary sort (sort by full name)
%         (case-sensitive) (default).
%      n: Sort by full name (case-insensitive) (alphabetic).
%      e: Sort by extension (alphabetic).
%      t: Sort by extension and where equal, sort further by full name
%         (case-insensitive) (alphabetic).
%      d: Sort by date and time (oldest first).
%      s: Sort by size (smallest first).
%      r: (Suffix this to any of the above, to sort in reverse order.)
%
%    GROUP:
%      n: Do not group (default).
%      d: Group directories first.
%      f: Group files first.
%
%  EXAMPLES:
%    dirc('C:\')
%    dirc('C:\Windows','de','n')
%    dirc('C:\','','t','d')
%
%  REMARKS:
%
%    Because FILEPARTS is used to parse the FULL ITEM NAME into ITEM NAME
%    and ITEM EXTENSION (as long as the item is a file), the function uses
%    additional time to run (assuming PARSE_ITEM_NAMES under CONFIGURABLE
%    OPTIONS is left enabled).
%
%    The ITEM EXTENSION, if present, does not include an initial dot. This
%    is unlike the output of the FILEPARTS function, where the ITEM
%    EXTENSION of the output does include an initial dot.
%
%    See the CONFIGURABLE OPTIONS section in the code for additional
%    options.
%
%  VERSION DATE: 2005.06.10
%  MATLAB VERSION: 7.0.1.24704 (R14) Service Pack 1
%
%  See also DIR, FILEPARTS.

%{
REVISION HISTORY:
2005.06.10: Added 'or' SORT_BY option.
2005.04.12: Removed undesirable 'clc' line from code.
2005.04.07: Original release.

KEYWORDS:
dir, directory, directories, directory listing, folder, folders, 
file, files, file name, file names, filename, filenames, fileparts, 
ext, extension
%}

%**************************************************************************

%% CONFIGURABLE OPTIONS

parse_item_names=1;
%If set to 1 (default), items are parsed into name and extension. If set to
%0, items are not parsed into name and extension, and those two columns in
%the output are left empty.

parse_dir_names=0;
%If set to 0 (default), only files are parsed into name and extension, and
%directories are not. If set to 1, both files and directories are parsed to
%name and extension. This applies only if PARSE_ITEM_NAMES is set to 1.

%**************************************************************************

%% Confirm FILTER value, if entered, is valid; else set default value.

if nargin>=2,
    switch filter
        case{'','a','ae','f','d','de'}
        otherwise
            error('Invalid filter option.')
    end
else
    filter='';
end

%--------------------------------------------------------------------------

%% Confirm SORT_BY value, if entered, is valid; else set default value.

if nargin>=3,
    switch sort_by
        case{'','o','or','n','nr','e','er','t','tr','d','dr','s','sr'}
        otherwise
            error('Invalid sort option.')
    end
else
    sort_by='';
end

%--------------------------------------------------------------------------

%% Confirm GROUP value, if entered, is valid; else set default value.

if nargin>=4,
    switch group
        case{'','n','d','f'}
        otherwise
            error('Invalid group option.')
    end
else
    group='';
end

%**************************************************************************

%% Get directory listing and convert it to cell format.

list=dir(dir_name);
list=struct2cell(list);
list=list';

%--------------------------------------------------------------------------

%% Insert columns for ITEM NAME and ITEM EXTENSION.

list(:,7:9)=list(:,2:4);
list(:,2:4)='';

%--------------------------------------------------------------------------

%% If PARSE_ITEM_NAMES is enabled, parse and store FULL ITEM NAME into ITEM
%  NAME and ITEM EXTENSION in LIST.

if parse_item_names

    list_items=size(list,1);
    for item_count=1:list_items

        %Query ITEM ISDIR status.
        item_isdir=list(item_count,6);
        item_isdir=cell2mat(item_isdir);

        %If ITEM is file or PARSE_DIR_NAMES is enabled, update LIST with
        %ITEM_NAME and ITEM_EXT.
        item_isfile=(item_isdir==0);
        if item_isfile || parse_dir_names

            %Query FULL_ITEM_NAME.
            full_item_name=list(item_count,1);
            full_item_name=cell2mat(full_item_name);

            %Generate ITEM_NAME and ITEM_EXT.
            [item_path,item_name,item_ext]=...
                fileparts([dir_name,'\',full_item_name]);

            %IF ITEM_EXT exists, remove dot from it.
            item_ext_size=numel(item_ext);
            item_ext_exists=(item_ext_size>0);
            if item_ext_exists
                item_ext=item_ext(2:end);
            end

            %Update LIST with ITEM_NAME and ITEM_EXT.
            list(item_count,2)={item_name};
            list(item_count,3)={item_ext};

        end

    end

end

%**************************************************************************

%% Filter LIST as relevant.

switch filter
    
    case{'','a'}
        
        %Do not delete anything.
        
    case{'ae'}
        
        %Delete '.' and '..' directories if they exist.
        if strcmp(cell2mat(list(1,1)),'.') && ...
           strcmp(cell2mat(list(2,1)),'..')
            list(1:2,:)=[];
        end
        
    case{'f'}
        
        %Determine directory indices.
        isdir_values=list(:,6);
        isdir_values=cell2mat(isdir_values);
        dir_indices=find(isdir_values==1);
        
        %Delete directories.
        list(dir_indices,:)=[];
        
    case{'d'}
        
        %Determine files.
        isdir_values=list(:,6);
        isdir_values=cell2mat(isdir_values);
        file_indices=find(isdir_values==0);
        
        %Delete files.
        list(file_indices,:)=[];
        
    case{'de'}
        
        %Determine file indices.
        isdir_values=list(:,6);
        isdir_values=cell2mat(isdir_values);
        file_indices=find(isdir_values==0);
        
        %Delete files.
        list(file_indices,:)=[];
        
        %Delete '.' and '..' directories if they exist.
        if strcmp(cell2mat(list(1,1)),'.') && ...
           strcmp(cell2mat(list(2,1)),'..')
            list(1:2,:)=[];
        end
        
end

%**************************************************************************

%% Sort LIST as relevant.

switch sort_by
    
    case{'','o','or'}
        
        %Use default sort.
        
    case{'n','nr'}
        
        %Sort by full name.
        full_item_names=list(:,1);
        full_item_names=lower(full_item_names);
        [full_item_names,index]=sortrows(full_item_names);
        list=list(index,:);
        
    case{'e','er'}
        
        %Sort by extension
        item_exts=list(:,3);
        item_exts_numel=size(item_exts,1);
        for item_count=1:item_exts_numel
            
            item_ext=item_exts(item_count);
            item_ext=cell2mat(item_ext);
            if isequal(item_ext,[])
                item_exts(item_count)={''};
            end
            
        end
        item_exts=lower(item_exts);
        [item_exts,index]=sortrows(item_exts);
        list=list(index,:);
        
    case{'t','tr'}
        
        %Sort by extension and where equal, sort further by full name
        %(executes in reverse).
        
        %Sort by full name.
        full_item_names=list(:,1);
        full_item_names=lower(full_item_names);
        [full_item_names,index]=sortrows(full_item_names);
        list=list(index,:);
        
        item_exts=list(:,3);
        item_exts_numel=size(item_exts,1);
        for item_count=1:item_exts_numel
            
            item_ext=item_exts(item_count);
            item_ext=cell2mat(item_ext);
            if isequal(item_ext,[])
                item_exts(item_count)={''};
            end
        
        %Sort by extension.
        end
        item_exts=lower(item_exts);
        [item_exts,index]=sortrows(item_exts);
        list=list(index,:);
        
    case{'d','dr'}
        
        %Sort by date and time.
        item_dates=list(:,4);
        item_dates=cell2mat(item_dates);
        item_dates=datenum(item_dates);
        [item_dates,index]=sortrows(item_dates);
        list=list(index,:);
        
    case{'s','sr'}
        
        %Sort by size
        item_sizes=list(:,5);
        item_sizes=cell2mat(item_sizes);
        [item_sizes,index]=sortrows(item_sizes);
        list=list(index,:);
        
end

%--------------------------------------------------------------------------

%% Reverse the sorted order if relevant.

if numel(sort_by)==2 && sort_by(2)=='r'
    list_items=size(list,1);
    list=list(list_items:-1:1,:);
end
 
%**************************************************************************

%% Group LIST as relevant.

switch group
    
    case{'','n'}
        
        %Do not group.
        
    case{'','d'}
        
        %Group directories first.
        
        %Determine directory indices.
        isdir_values=list(:,6);
        isdir_values=cell2mat(isdir_values);
        dir_indices=find(isdir_values==1);

        %Determine file indices.
        isdir_values=list(:,6);
        isdir_values=cell2mat(isdir_values);
        file_indices=find(isdir_values==0);
        
        %Merge grouping indices.
        regrouping_indices=[dir_indices;file_indices];
        
        %Group
        list=list(regrouping_indices,:);
        
    case{'','f'}
        
        %Group files first.
        
        %Determine directory indices.
        isdir_values=list(:,6);
        isdir_values=cell2mat(isdir_values);
        dir_indices=find(isdir_values==1);

        %Determine file indices.
        isdir_values=list(:,6);
        isdir_values=cell2mat(isdir_values);
        file_indices=find(isdir_values==0);
        
        %Merge grouping indices.
        regrouping_indices=[file_indices;dir_indices];
        
        %Group
        list=list(regrouping_indices,:);
    
end

%**************************************************************************