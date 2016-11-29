% Access routines for Oceans-EEZ data products:  /home/eez_data/software/matlab
%            ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%   See also  http: //www.marine.csiro.au/eez_data/doc/index.html
%
%   - - - - -  CSIRO Atlas of Regional Seas (CARS) access scripts  - - - - -
% get_clim:   alternative to get_clim_casts (slower but more general).
%
% getmap:     extract a 2D horizontal slice of a given climatology
%
% s_from_direct_ts:  s casts from t casts, using t-s climatology
%
% getsection: (superceded for most purposes by get_clim) extract vertical
%             profiles at arbitrary geographic positions
% getchunk:   extract a 3D chunk of a property map (could also use get_clim)
% get_clim_casts:  extract property from CARS for given locations, depths, and
%             optionally days-of-year.
% map_index:  obscure guide to grungy details of different CARS files 
%
%   - - - - - World Ocean Atlas (WOA) access scripts - - - - -
% get_woa_profiles:
%
%   - - - - - related utility functions - - - - -
% dep_csl, dep_std, csl_dep, std_dep:  Conversion between depth and levels
% eezgrid:    create the lat/long grids on which the CARS is based.
% atday:      mean and harmonics -> values at given day of year.
% atdaypos:   mean and harmonics -> values at given positions and day of year.
% time2doy    days since start of 1900 to day_of_year   
% time2greg   days since start of 1900 to gregorian time
% greg2time   gregorian time to days since start of 1900
%
%    - - -  CSL (Standard Level) hydrographic data access  - - -
% get_all_csl:  Access to WOD98, NIWA, CSIRO, and CRC (Aurora) CTD, bottle,
%               and XBT data.
% getCSIROcsl, getCSIROxbt, getwodcsl:   called by get_all_csl, but can be
%               used separately.
%
%    - - -  Observed Level or High-res (2db) hydrographic data access  - - -
% gethydobs:  Access to WOD98 CTD, bottle, and XBT data.
% getwod98:  Differs from GETHYDOBS in all vars required to be from same file
%        type, and no cell-output option (which makes it much faster and simpler). 
%
%    - - -  CMR Data Centre CTD archive access 
% ctd_select:  GUI menu to select from CSIRO CTD station list
% ctdExtract2: skeleton script to be adapted by users to extract CSIRO CTDs
%
%    - - -  Validate MECO model files by comparison with hydro cast data
% validate:  GUI to control comparison calculations and plot generation
% validate_nogui:   Non-GUI earlier version
%
%   - - - - - Pathfinder SST - - - - -
% pfsst:  Retrieves a map of Pathfinder SST for a given region and date.
% pftseries: 
% 
%   - - - - - Other SST - - - - -
% get_sst_xy:  Retrieve SST at place/time, from local gridded SST datasets
%
%   - - - - - Altimeter - - - - -
% altim - C program - see web reference above.
% get_alt_xy:  Retrieve height at place/time, from gridded altimeter 
% get_altim_3d:  Extract data from "altim" netcdf files
% view_altim:  quick inspection of contents of "altim" netcdf files
%
%   - - - - - Bathymetry - - - - -
% get_bath:  get depths at locations, from any bathy datasets
% get_bath_agso:  get a chunk of full resolution AGSO bathy
% topongdc: access just NGDC 8.2 bathy
% topo: access just Terrainbase (ETOPO5) bathy
%   Superceded:
% agso_bath:  get a chunk of full 30-sec resolution AGSO bathy
% agso_bath_xy:  get depths at locations, interpolated from 30-sec AGSO bathy
% get_bath15:  access AusBath15, Terrainbase, NGDC.
%
%    - - -  Background functions (not for users to invoke directly)
% For ctd_select:  ctd_sel_util.m, dispsel_util.m
% For validate:  val_util.m,  validate_help.txt
% Other: scaleget, word_chop, clname, interp3_clim, minjd, suf_to_par
%    See ./private/Contents.m for others
%
%                                     This file updated 8/1/03 by Jeff Dunn

%===========================================================================
% - - - Old stuff (some now removed)
%
%    - - - Standard Level cast access functions
% getNODC:    Matlab5 access to WOA94 casts
% getNODC_var:   Matlab4 access to WOA94 casts
% getCSIRO: was used to access csiro_ctd.nc - an SL (not CSL) archive file.
%
