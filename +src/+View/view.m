classdef view < handle
    properties
        range1 = 0
        range2 = 0.6
    end

    methods
        function render(obj, data, currentAngle)
            if isempty(data)
                return
            end

            % 1. PERSISTENT FIGURE CHECK
            fig = findobj('Type', 'figure', 'Tag', 'RadarScanner');
            if isempty(fig)
                fig = figure('Color', 'w', 'Tag', 'RadarScanner', 'Name', 'Live Radar Feed');
                ax = axes('Parent', fig);
                hold(ax, 'on');
                axis(ax, 'equal');
                axis(ax, 'off');
                obj.drawStaticElements(ax);
            else
                ax = findobj(fig, 'Type', 'axes');
                hold(ax, 'on'); 
            end

            % 2. ROTATION & COORDINATE CALCULATION
            fov_deg = 60;          
            intensity_profile = max(abs(data), [], 1); 
            num_bins = length(intensity_profile);
            
            % Offset the angles based on the motor's current position
            % MATLAB 0 radians is East, so we subtract from 90 to make 0 degrees North
            start_angle = currentAngle - (fov_deg / 2);
            end_angle = currentAngle + (fov_deg / 2);
            angles = linspace(deg2rad(90 - end_angle), deg2rad(90 - start_angle), 100); 
            
            ranges = linspace(obj.range1, obj.range2, num_bins);
            [theta, r] = meshgrid(angles, ranges);
            [X, Y] = pol2cart(theta, r);
            Z = repmat(intensity_profile', 1, length(angles));
            
            % 3. UPDATE PLOT
            surf(ax, X, Y, Z, 'EdgeColor', 'none');
            colormap(ax, parula); 
            
            % Maintain layering
            uistack(findobj(ax, 'Tag', 'SensorIcon'), 'top');
        end
    end

    methods (Access = private)
        function drawStaticElements(obj, ax)
            max_r = obj.range2;
            full_phi = linspace(0, 2*pi, 200);
            
            % Background and Rings
            fill(ax, max_r*cos(full_phi), max_r*sin(full_phi), [0.15 0.15 0.15], 'EdgeColor', [0.3 0.3 0.3]); 
            ring_steps = linspace(0, max_r, 4);
            for r_val = ring_steps(2:end)
                plot(ax, r_val*cos(full_phi), r_val*sin(full_phi), ':', 'Color', [0.5 0.5 0.5]);
                text(ax, 0, r_val + 0.02, [num2str(r_val) 'm'], 'Color', 'w', 'FontSize', 8, 'Horiz', 'center');
            end
            
            % Compass Labels
            text(ax, 0, max_r + 0.1, '0°', 'FontWeight', 'bold', 'Horiz', 'center');
            text(ax, max_r + 0.1, 0, '90°', 'FontWeight', 'bold');
            
            % Sensor Icon
            plot(ax, 0, 0, 'v', 'MarkerFaceColor', 'y', 'MarkerSize', 8, 'Tag', 'SensorIcon');
        end
    end
end