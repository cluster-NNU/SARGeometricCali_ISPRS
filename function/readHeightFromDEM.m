function HInit = readHeightFromDEM(GCPResultLoc,DEM,DEMR)
%  READHEIGHTFROMDEM Read elevation value from DEM using latitude and longitude
% 
% Detailed description of this function.
% Read DEM data
latInit = GCPResultLoc(1);
lonInit = GCPResultLoc(2);
%   ASTGTM2_N41E087_dem.tif  F:\aAirborne SAR image target positioning technology\Malan area 30m DEM data\ASTDEM.tif
%   F:\aAirborne SAR image target positioning technology\Malan area 90m DEM data\srtm_54_041.tif
%   "F:\aAirborne SAR image target positioning technology\Malan area 30m DEM data\ASTDEM.tif"
%    F:\aAirborne SAR image target positioning technology\Xinjiang 12.5m DEM\Xinjiang WGS84 clip2.TIF
%   F:\aAirborne SAR image target positioning technology\Malan SAR image and parameter files\70~80km operating range-Flat area - multiple feature points\DEM12_.tif
[DEMi,DEMj] = geographicToIntrinsic(DEMR,latInit,lonInit); 
% [DEMi1,DEMj1] = latlon2pix(DEMR,latInit,lonInit);          % Convert lat/lon to DEM pixel position
% [lat,lon] = intrinsicToGeographic(DEMR,DEMi,DEMj);
HInit = double(DEM(int32(DEMj),int32(DEMi)));            % Target initial elevation, obtained from initial lat/lon and DEM
% Obtain fast positioning initial values and elevation  
% disp(['Positioning initial values BLH: ',num2str(latInit),' ',num2str(lonInit),' ',num2str(HInit)]);
end