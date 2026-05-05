classdef model < handle
    % MODEL Holds the current radar sweep matrix.
    % Data is set directly by the controller (no file I/O).

    properties
        M   % double matrix: N_sweeps x N_range_bins
    end

    methods
        function obj = model()
            obj.M = [];
        end

        function setData(obj, matrix)
            % Called by the controller after receiving data directly from Python.
            if isempty(matrix)
                warning('Model: received empty matrix.');
            end
            obj.M = matrix;
        end
    end
end