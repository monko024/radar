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

        function render(obj, data, currentAngle, ax)
            if nargin > 3 && ~isempty(ax), obj.axHandle = ax; end
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

            % DRAWING LOGIC
            num_sweeps = size(data, 1);
            num_bins   = size(data, 2);
            r = linspace(obj.range1, obj.range2, num_bins);
            
            % --- FIX: 60 DEGREE WIDE CONE ---
            % Centered at currentAngle, spread is +/- 30 degrees
            theta_rad = deg2rad(linspace(currentAngle - 30, currentAngle + 30, num_sweeps));
            
            [THETA, R] = meshgrid(theta_rad, r);
            X = R .* cos(THETA);
            Y = R .* sin(THETA);

            h = surf(targetAx, X, Y, zeros(size(X)), data', ...
                 'EdgeColor', 'none', 'FaceColor', 'interp', 'Tag', 'RadarSlice');
            
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
            phi = linspace(0, 2*pi, 100);
            
            for r_val = linspace(0, max_r, 4)
                plot3(ax, r_val*cos(phi), r_val*sin(phi), ones(1,100)*0.1, ':', 'Color', [0.4 0.4 0.4]);
            end
            
            plot3(ax, 0, 0, 0.5, 'wo', 'MarkerFaceColor', 'r', 'Tag', 'SensorIcon');
            
            axis(ax, 'equal');
            axis(ax, [-max_r-0.1 max_r+0.1 -max_r-0.1 max_r+0.1]);
            ax.Color = 'none'; ax.XColor = 'none'; ax.YColor = 'none';
            view(ax, 2);
        end
    end
end