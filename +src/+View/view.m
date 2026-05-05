classdef view < handle
    properties
        range1 = 0.2
        range2 = 1.0
        axHandle
    end

    methods
        function setRange(obj, r1, r2)
            obj.range1 = r1;
            obj.range2 = r2;
        end

        function render(obj, data, currentAngle, stepAngle, ax)
            % Sync axes handle
            if nargin > 4 && ~isempty(ax), obj.axHandle = ax; end
            if isempty(obj.axHandle) || ~isvalid(obj.axHandle), return; end
            
            targetAx = obj.axHandle;
            hold(targetAx, 'on');

            % CLEAR LOGIC
            if isempty(data)
                slices = findobj(targetAx, 'Tag', 'RadarSlice');
                if ~isempty(slices), delete(slices); end
                if isempty(findobj(targetAx, 'Tag', 'SensorIcon'))
                    obj.drawStaticElements(targetAx);
                end
                return;
            end

            % DYNAMIC CONE WIDTH CALCULATION
            % Instead of +/- 10 degrees, we use half of the step angle 
            % to ensure the slices touch perfectly without overlapping or gaps.
            num_sweeps = size(data, 1);
            num_bins   = size(data, 2);
            r = linspace(obj.range1, obj.range2, num_bins);
            
            % Center the cone on currentAngle and spread it by stepAngle
            half_step = stepAngle / 2;
            theta_deg = linspace(currentAngle - half_step, currentAngle + half_step, num_sweeps);
            theta_rad = deg2rad(theta_deg);
            
            [THETA, R] = meshgrid(theta_rad, r);
            X = R .* cos(THETA);
            Y = R .* sin(THETA);

            % Plotting at Z=0 for 2D look
            h = surf(targetAx, X, Y, zeros(size(X)), data', ...
                 'EdgeColor', 'none', 'FaceColor', 'interp', 'Tag', 'RadarSlice');
            
            % Ensure layers stay correct
            if isempty(findobj(targetAx, 'Tag', 'SensorIcon'))
                obj.drawStaticElements(targetAx);
            end
            uistack(h, 'bottom');
            uistack(findobj(targetAx, 'Tag', 'SensorIcon'), 'top');
        end
    end

    methods (Access = private)
        function drawStaticElements(obj, ax)
            cla(ax);
            hold(ax, 'on');
            max_r = obj.range2;
            phi = linspace(0, 2*pi, 150);
            
            % Draw range rings
            ring_vals = linspace(0, max_r, 4);
            for r_val = ring_vals(2:end)
                plot3(ax, r_val*cos(phi), r_val*sin(phi), ones(size(phi))*0.1, ...
                    ':', 'Color', [0.4 0.4 0.4], 'LineWidth', 0.5);
                text(ax, r_val*cos(pi/4), r_val*sin(pi/4), 0.2, [num2str(r_val) 'm'], ...
                    'Color', 'w', 'FontSize', 7);
            end
            
            % Center point
            plot3(ax, 0, 0, 0.5, 'wo', 'MarkerFaceColor', 'r', 'MarkerSize', 6, 'Tag', 'SensorIcon');
            
            axis(ax, 'equal');
            limit = max_r + 0.1;
            axis(ax, [-limit limit -limit limit]);
            ax.Color = 'none'; ax.XColor = 'none'; ax.YColor = 'none';
            view(ax, 2);
        end
    end
end