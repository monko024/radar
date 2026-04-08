classdef model<handle


    properties
        M
    end

    methods
        function obj=model()
            obj.M=[];             
        end

        function loadData(obj)
            obj.M = readmatrix('radar_capture.csv');
            %tu bude filter, pripadne nejake spracovanie dat
        end
    end
end