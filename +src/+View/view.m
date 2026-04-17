classdef view < handle

    properties
        range1 = 0
        range2 = 0.6
    end

    methods
        function obj = view()
        end

        function render(obj, data, figHandle)
            if isempty(data)
                return
            end

            % Use existing figure and clear it
            figure(figHandle);
            clf;
            hold on; axis equal; axis off;

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

            % 1. BACKGROUND
            full_phi = linspace(0, 2*pi, 200);
            fill(max_range*cos(full_phi), max_range*sin(full_phi), [0.15 0.15 0.15], ...
                'EdgeColor', [0.3 0.3 0.3], 'LineWidth', 1.5);

            % 2. MEASUREMENT CONE
            surf(X, Y, Z, 'EdgeColor', 'none');
            colormap(parula);

            % 3. DISTANCE RINGS
            ring_num = round((obj.range2) / 3, 1);
            for ring_r = [ring_num, 2*ring_num, 3*ring_num]
                plot(ring_r*cos(full_phi), ring_r*sin(full_phi), ':', 'Color', [0.5 0.5 0.5]);
                text(0, ring_r + 0.03, [num2str(ring_r) 'm'], 'FontSize', 8, 'Color', 'w', 'Horiz', 'center');
            end

            % 4. CONE BORDERS
            plot([0, X(end,1)], [0, Y(end,1)], 'w-', 'LineWidth', 1.2);
            plot([0, X(end,end)], [0, Y(end,end)], 'w-', 'LineWidth', 1.2);

            % 5. COMPASS TICKS
            text(0, max_range + 0.08, '0°', 'FontWeight', 'bold', 'Horiz', 'center');
            text(0, -max_range - 0.08, '180°', 'FontWeight', 'bold', 'Horiz', 'center');
            text(max_range + 0.08, 0, '90°', 'FontWeight', 'bold', 'Vert', 'middle');
            text(-max_range - 0.08, 0, '270°', 'FontWeight', 'bold', 'Vert', 'middle');

            % 6. SENSOR ICON
            plot(0, 0, 'v', 'MarkerFaceColor', 'y', 'MarkerEdgeColor', 'w', 'MarkerSize', 8);

            % STYLING
            c = colorbar;
            c.Label.String = 'Amplitude';
            title(sprintf('Top-Down Radar View — Position %d of %d', size(data, 1), size(data, 1)), 'FontSize', 14);

            drawnow; % force immediate plot update
        end
    end
end
