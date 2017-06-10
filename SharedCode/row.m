% ROW  Ensure 1-D object is a row vector

function rin = row(vin)

[s1 s2] = size(vin);
if s1 > 1 & s2==1
   rin = vin.';
else
   rin = vin;
end
