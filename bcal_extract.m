%  bcal_extract
% 
%  This is designed to extract a single set of calibration coeffs for
%  backscatter calculations because there are so many versions with
%  different wavelengths even on a single flato (the record at this point
%  is 4).  
%
%  usage:  bcoeff=bcal_extract(bc,wv)
%  where bc is the cal coeff set for a single float
%  and wv is the wavelength of the required sensor
%    note the current wavelengths are:
%  700 (the main one found on both the FLTNU and FLBB2 sensors)
%  532 (found on the FLBB2 sensors)

%  All Eco sensors are denoted as 'xxx.2' so  their cal coeffs can be
%     identified:
%  470.2 (found on the eco puck sensors)
%  700.2 (found on the eco sensors and duplicating teh wavelength of
%    another sensor on the same flaot so this will be the SECOND version in
%    all data files.
%  532.2 (similarly, an eco sensor that duplicates an FLBB sensor so 
%    needs to be distinguishable) 

function bcoef = bcal_extract(bc,wv)


if wv==700  % primary 700nm sensors on FLBB and FLBB2 instruments
    b.FLBBdc=bc.FLBB700dc;
    b.FLBBscale=bc.FLBB700scale;
    b.BBPangle=bc.BBP700angle;
    b.BBPChi=bc.BBP700Chi;
elseif wv==532  %secondary sensor on FLBB2 instruments
    b.FLBBdc=bc.FLBB532dc;
    b.FLBBscale=bc.FLBB532scale;
    b.BBPangle=bc.BBP532angle;
    b.BBPChi=bc.BBP532Chi;
elseif wv==470.2  %secondary sensor on FLBB2 instruments
    b.FLBBdc=bc.EcoFLBB470dc;
    b.FLBBscale=bc.EcoFLBB470scale;
    b.BBPangle=bc.EcoFLBB470angle;
    b.BBPChi=bc.EcoFLBB470Chi;
elseif wv==700.2  %secondary sensor on FLBB2 instruments
    b.FLBBdc=bc.EcoFLBB700dc;
    b.FLBBscale=bc.EcoFLBB700scale;
    b.BBPangle=bc.EcoFLBB700angle;
    b.BBPChi=bc.EcoFLBB700Chi;
elseif wv==532.2  %secondary sensor on FLBB2 instruments
    b.FLBBdc=bc.EcoFLBB532dc;
    b.FLBBscale=bc.EcoFLBB532scale;
    b.BBPangle=bc.EcoFLBB532angle;
    b.BBPChi=bc.EcoFLBB532Chi;
end

bcoef = b;
return
