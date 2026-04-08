classdef view<handle
    %VIEW Summary of this class goes here
    %   Detailed explanation goes here

    properties
        range1=0
        range2=0.6
    end

    methods
        function obj=view()
        
        end
        
        function render(obj,data)
            if isempty(data)
                return
            end

            fov_deg = 60;          
            max_range = obj.range2;       
            min_range = obj.range1;
            
            % --- DATA PREP ---
            intensity_profile = max(abs(data), [], 1); 
            num_bins = length(intensity_profile);
            
            angles = linspace(deg2rad(90 - fov_deg/2), deg2rad(90 + fov_deg/2), 100); 
            ranges = linspace(min_range, max_range, num_bins);
            [theta, r] = meshgrid(angles, ranges);
            [X, Y] = pol2cart(theta, r);
            Z = repmat(intensity_profile', 1, length(angles));
            
            % --- PLOTTING ---
            figure('Color', 'w');
            hold on; axis equal; axis off;
            
            % 1. DRAW THE EMPTY BACKGROUND (Darker for contrast)
            full_phi = linspace(0, 2*pi, 200);
            fill(max_range*cos(full_phi), max_range*sin(full_phi), [0.15 0.15 0.15], ...
                'EdgeColor', [0.3 0.3 0.3], 'LineWidth', 1.5); 
            
            % 2. PLOT THE MEASUREMENT CONE
            surf(X, Y, Z, 'EdgeColor', 'none');
            colormap(parula); 
            
            % 3. DRAW DISTANCE RINGS (Full 360°)
            ring_num=round((obj.range2)/3,1);
            for ring_r = [ring_num,2*ring_num,3*ring_num]
                plot(ring_r*cos(full_phi), ring_r*sin(full_phi), ':', 'Color', [0.5 0.5 0.5]);
                text(0, ring_r + 0.03, [num2str(ring_r) 'm'], 'FontSize', 8, 'Color', 'w', 'Horiz', 'center');
            end
            
            % 4. DRAW THE CONE BORDERS
            plot([0, X(end,1)], [0, Y(end,1)], 'w-', 'LineWidth', 1.2);
            plot([0, X(end,end)], [0, Y(end,end)], 'w-', 'LineWidth', 1.2);
            
            % 5. ADD COMPASS TICKS
            text(0, max_range + 0.08, '0°', 'FontWeight', 'bold', 'Horiz', 'center');
            text(0, -max_range - 0.08, '180°', 'FontWeight', 'bold', 'Horiz', 'center');
            text(max_range + 0.08, 0, '90°', 'FontWeight', 'bold', 'Vert', 'middle');
            text(-max_range - 0.08, 0, '270°', 'FontWeight', 'bold', 'Vert', 'middle');
            
            % 6. RADAR SENSOR ICON
            plot(0, 0, 'v', 'MarkerFaceColor', 'y', 'MarkerEdgeColor', 'w', 'MarkerSize', 8);
            
            % STYLING
            c = colorbar;
            c.Label.String = 'Amplitude';
            title('Top-Down Radar View ', 'FontSize', 14);
            
            %view(2);
            margin = 0.2;
            xlim([-max_range-margin, max_range+margin]);
            ylim([-max_range-margin, max_range+margin]);
        end

    end
end