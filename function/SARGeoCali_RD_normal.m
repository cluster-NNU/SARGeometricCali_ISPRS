function [range_bias, pos_bias] = SARGeoCali_RD_normal(m, sat_positions_ob, control_points_ob, measured_ranges, sat_velocities_ob, wavelength, doppler_shifts_ob)
% Normalized RD equation solver
% Input parameters:
%   m - number of control points
%   sat_positions_ob - satellite observed positions (m×3 matrix)
%   control_points_ob - control point observed positions (m×3 matrix)
%   measured_ranges - measured range vector (m×1)
%   sat_velocities_ob - satellite observed velocities (m×3 matrix)
%   wavelength - radar wavelength (meters)
%   doppler_shifts_ob - Doppler shift observations (m×1)
% Output:
%   range_bias - solved range bias
%   pos_bias - solved along-track position bias

    % Set solver options
    options = optimoptions('fsolve', ...
        'Display', 'off', ...
        'MaxIterations', 3000, ...
        'MaxFunctionEvaluations', 6000, ...
        'FunctionTolerance', 1e-10, ...
        'StepTolerance', 1e-10, ...
        'Algorithm', 'levenberg-marquardt');
    
    % Initial guess values
    x0 = [0; 0];
    
    % Call fsolve to solve
    [x, ~, exitflag] = fsolve(@nested_equations_RD_normal, x0, options);
    
    % Check solver status
    if exitflag <= 0
        warning('Equation solving may not have converged, exitflag = %d', exitflag);
    end
    
    % Return results
    range_bias = x(1);
    pos_bias = x(2);
    
    % Nested normalized RD equations
    function F = nested_equations_RD_normal(x)
        F = zeros(2*m, 1);
        
        % Extract parameters
        range_bias = x(1);       
        pos_bias = x(2);         
        
        % Range equation
        for i = 1:m
            corrected_sat_pos = sat_positions_ob(i,:)' - [0; pos_bias; 0];
            range_vector = corrected_sat_pos - control_points_ob(i,:)';
            F(i) = (norm(range_vector) - (measured_ranges(i) - range_bias))*10;
        end

        % Doppler equation
        for i = 1:m
            range_vector = (sat_positions_ob(i,:)' - [0; pos_bias; 0]) - control_points_ob(i,:)';
            F(i+m) = (dot(range_vector, sat_velocities_ob(i,:)') - ...
                     (measured_ranges(i)-range_bias) * wavelength * doppler_shifts_ob(i)/2) / ...
                     norm(sat_velocities_ob);
        end
    end
end

