function unpack_model(model)
% UNPACK_MODEL Unpacks a model structure from a .mat file into workspace variables.
%
%   UNPACK_MODEL(matfile)
%   Loads the .mat file containing a structure named 'model' with fields
%   Soleus, Gastroc, and Tibialis. Each substructure field (e.g., scale_emg)
%   is extracted into a new variable named <Muscle>_<Field> (e.g. Soleus_scale_emg).


    % Get top-level muscle names
    muscles = fieldnames(model);
    
    for i = 1:numel(muscles)
        muscleName = muscles{i};
        muscleStruct = model.(muscleName);
        
        % Skip non-struct fields (e.g. nmuscles if present)
        if ~isstruct(muscleStruct)
            continue
        end
        
        % Get all variable names inside this muscle
        vars = fieldnames(muscleStruct);
        
        % Loop through each and assign to base workspace
        for j = 1:numel(vars)
            varName = sprintf('%s_%s', muscleName, vars{j});
            varValue = muscleStruct.(vars{j});
            assignin('base', varName, varValue);
        end
    end

    fprintf('All model variables have been unpacked into the workspace.\n');
end