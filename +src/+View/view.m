classdef view < handle
    properties
        range1 = 0
        range2 = 0.6
    end

    methods
        function render(obj, data, currentAngle)
            % Check if data is valid
            if isempty(data)
                warning('Data is empty. Skipping render.');
                return;
            end

            % 1. PERSISTENT FIGURE CHECK
            fig = findobj('Type', 'figure', 'Tag', 'RadarScanner');
            if isempty(fig)
                % Create figure with a dark background to avoid the "white screen"
                fig = figure('Color', [0.1 0.1 0.1], ...
                             'Tag', 'RadarScanner', ...
                             'Name', 'Live Radar Feed', ...
                             'NumberTitle', 'off');
                
                ax = axes('Parent', fig);
                hold(ax, 'on');
                axis(ax, 'equal');
                
                % Set axis limits based on range2
                limit = obj.range2 + 0.1;
                axis(ax, [-limit limit -limit limit]);
                
                % Turn off default axis lines but keep the plot area
                ax.Color = 'none';
                ax.XColor = 'none';
                ax.YColor = 'none';
                
                obj.drawStaticElements(ax);
            else
                ax = findobj(fig, 'Type', 'axes');
            end

            % 2. ROTATION & COORDINATE CALCULATION
            fov_deg = 60;          
            % Ensure data is processed into a 1D profile
            intensity_profile = max(abs(data), [], 1); 
            num_bins = length(intensity_profile);
            
            % Calculate angular spread
            start_angle = currentAngle - (fov_deg / 2);
            end_angle = currentAngle + (fov_deg / 2);
            
            % Convert to radians and adjust 0 deg to North (90 rad)
            angles = linspace(deg2rad(90 - end_angle), deg2rad(90 - start_angle), 50); 
            ranges = linspace(obj.range1, obj.range2, num_bins);
            
            [theta, r] = meshgrid(angles, ranges);
            [X, Y] = pol2cart(theta, r);
            
            % Create Z data for the surf plot
            % We repeat the intensity profile across all angles in the slice
            Z_color = repmat(intensity_profile', 1, length(angles));
            
            % To ensure the radar data is visible ABOVE the background, we use a small Z offset
            Z_height = ones(size(Z_color)) * 0.05; 
            
            % 3. UPDATE PLOT
            % We use 'Tag' so we can clear old slices if you want a clean sweep
            % delete(findobj(ax, 'Tag', 'RadarSlice')); % Uncomment to clear previous step
            
            s = surf(ax, X, Y, Z_height, Z_color, ...
                'EdgeColor', 'none', ...
                'FaceColor', 'interp', ...
                'Tag', 'RadarSlice');
            
            colormap(ax, parula); 
            view(ax, 2); % Ensure top-down view
            
            % Bring Sensor Icon to front
            uistack(findobj(ax, 'Tag', 'SensorIcon'), 'top');
        end
    end

    methods (Access = private)
        function drawStaticElements(obj, ax)
            max_r = obj.range2;
            full_phi = linspace(0, 2*pi, 200);
            
            % Draw Background Disk at Z = 0
            fill3(ax, max_r*cos(full_phi), max_r*sin(full_phi), zeros(1,200), ...
                  [0.15 0.15 0.15], 'EdgeColor', [0.3 0.3 0.3]); 
            
            % Draw Range Rings
            ring_steps = linspace(0, max_r, 4);
            for r_val = ring_steps(2:end)
                plot3(ax, r_val*cos(full_phi), r_val*sin(full_phi), ones(1,200)*0.01, ...
                      ':', 'Color', [0.5 0.5 0.5]);
                text(ax, 0, r_val, 0.02, [num2str(r_val) 'm'], ...
                     'Color', 'w', 'FontSize', 8, 'Horiz', 'center');
            end
            
            % Degree Labels
            text(ax, 0, max_r + 0.05, 0.02, '0° N', 'Color', 'w', 'FontWeight', 'bold', 'Horiz', 'center');
            text(ax, max_r + 0.05, 0, 0.02, '90° E', 'Color', 'w', 'FontWeight', 'bold');
            
            % Sensor Icon (at the center, elevated slightly)
            plot3(ax, 0, 0, 0.1, 'v', 'MarkerFaceColor', 'y', 'MarkerEdgeColor', 'k', ...
                  'MarkerSize', 10, 'Tag', 'SensorIcon');
        end
    end
end