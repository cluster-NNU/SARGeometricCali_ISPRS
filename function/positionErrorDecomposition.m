function [RangeError,AmzithError] = positionErrorDecomposition(flightAngle, positionError, RadarDirection)

V = positionError; % [east error, north error]

    if RadarDirection==1
        %% Radar right-looking
        theta = 360-flightAngle;
        translation = [0 0];
        tform = rigidtform2d(theta,translation);
        
        % scatter(tform)
        result = V*tform.R;
        
        % Azimuth and range positioning errors
        AmzithError = result(2);
        RangeError = result(1);
    else
        %% Radar left-looking
        theta = 90-flightAngle;
        translation = [0 0];
        tform = rigidtform2d(theta,translation);
        
        % scatter(tform)
        result = V*tform.R;
        
        % Azimuth and range positioning errors
        AmzithError = result(1);
        RangeError = result(2);
    end

end 
