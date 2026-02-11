% Select folder containing .mat files
data_folder = uigetdir(pwd, 'Select folder with .mat files');
% Define output folder (adjust if needed)
output_folder = fullfile('Pot_data/');
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end
% Get a list of all .mat files in the selected folder
mat_files = dir(fullfile(data_folder, '*.mat'));
% Define the list of signal names to extract
signal_names = {...
'rr_pot_travel_distance', ...
'rl_pot_travel_distance', ...
'fr_pot_travel_distance', ...
'fl_pot_travel_distance', ...
'accX', ...
'accY', ...
'dash_se', ...
'amk_actual_speed0', ...
'amk_actual_speed1', ...
'amk_actual_speed2', ...
'amk_actual_speed3', ...
'te_main_APPS', ...
'te_main_BPSp', ...
'te_main_BPSe', ...
'Roll', ...
'Pitch',...
''};

% Loop through each .mat file
for i = 1:length(mat_files)
    % Load the file
    file_path = fullfile(mat_files(i).folder, mat_files(i).name);
    data = load(file_path);
    
    % Initialize a structure to hold the desired signals
    temp_data = struct();
    
    % First pass: collect data and find signal lengths
    max_signal_length = 0;
    for j = 1:length(signal_names)
        field = signal_names{j};
        if isempty(field)
            continue;
        end
        
        if isfield(data, field)
            % Store the original raw data
            temp_data.(field) = data.(field);
            
            % Check data structure and get signal length
            if isstruct(data.(field)) && isfield(data.(field), 'signals') && isfield(data.(field).signals, 'values')
                signal_length = length(data.(field).signals.values);
            else
                signal_length = length(data.(field));
            end
            
            % Keep track of maximum signal length
            max_signal_length = max(max_signal_length, signal_length);
        end
    end
    
    % If no signals were found, skip this file
    if max_signal_length == 0
        warning('No valid signals found in file %s. Skipping.', mat_files(i).name);
        continue;
    end
    
    % Second pass: find potentiometer signals to detect the dynamic region
    pot_fields = {};
    for j = 1:length(signal_names)
        field = signal_names{j};
        if isempty(field)
            continue;
        end
        
        if isfield(data, field) && contains(field, 'pot_travel_distance')
            pot_fields{end+1} = field;
        end
    end
    
    % Initialize dynamic region boundaries to default values
    start_dynamic = 1;
    end_dynamic = max_signal_length;
    
    % Only attempt to detect dynamic regions if we have potentiometer signals
    if ~isempty(pot_fields)
        start_transitions = [];
        end_transitions = [];
        
        for j = 1:length(pot_fields)
            pot_field = pot_fields{j};
            
            % Get the signal values
            if isstruct(data.(pot_field)) && isfield(data.(pot_field), 'signals') && isfield(data.(pot_field).signals, 'values')
                signal_values = data.(pot_field).signals.values;
            else
                signal_values = data.(pot_field);
            end
            
            % Skip if signal is too short
            if length(signal_values) < 20
                continue;
            end
            
            % Detect steady-state regions
            window_size = min(100, floor(length(signal_values)/10)); 
            
            % Calculate rolling standard deviation
            rolling_std = zeros(length(signal_values) - window_size + 1, 1);
            for k = 1:(length(signal_values) - window_size + 1)
                rolling_std(k) = std(signal_values(k:(k+window_size-1)));
            end
            
            % Find regions with low standard deviation (steady-state)
            threshold = 5; % Adjust this threshold based on your data
            is_steady = rolling_std < threshold;
            
            % Find transition from steady to dynamic and back
            for k = 1:(length(is_steady)-1)
                if is_steady(k) && ~is_steady(k+1)
                    % Transition from steady to dynamic
                    start_transitions(end+1) = k + floor(window_size/2);
                elseif ~is_steady(k) && is_steady(k+1)
                    % Transition from dynamic to steady
                    end_transitions(end+1) = k + floor(window_size/2);
                end
            end
        end
        
        % Determine the global dynamic region
        if ~isempty(start_transitions)
            start_dynamic = min(start_transitions);
        end
        
        if ~isempty(end_transitions)
            end_dynamic = max(end_transitions);
        end
        
        % Safety check: ensure end is after start
        if end_dynamic <= start_dynamic
            end_dynamic = max_signal_length;
        end
    end
    
    % Now create trimmed versions of each signal
    for j = 1:length(signal_names)
        field = signal_names{j};
        if isempty(field)
            continue;
        end
        
        if isfield(data, field)
            % Create a trimmed version with "_offset" suffix instead of "_trimmed"
            offset_field = [field '_offset'];
            
            % Copy the structure for the trimmed version
            if isstruct(data.(field))
                temp_data.(offset_field) = data.(field);
                
                % If the structure has signals.values
                if isfield(data.(field), 'signals') && isfield(data.(field).signals, 'values')
                    signal_length = length(data.(field).signals.values);
                    
                    % Ensure indices are within bounds
                    valid_start = max(1, min(start_dynamic, signal_length));
                    valid_end = max(valid_start, min(end_dynamic, signal_length));
                    
                    % Apply trimming to signals.values
                    temp_data.(offset_field).signals.values = data.(field).signals.values(valid_start:valid_end);
                end
                
                % If the structure has a time field at the top level
                if isfield(data.(field), 'time')
                    time_length = length(data.(field).time);
                    
                    % Ensure indices are within bounds
                    valid_start = max(1, min(start_dynamic, time_length));
                    valid_end = max(valid_start, min(end_dynamic, time_length));
                    
                    % Apply trimming to time
                    temp_data.(offset_field).time = data.(field).time(valid_start:valid_end);
                end
            else
                % If the data is stored directly
                signal_length = length(data.(field));
                
                % Ensure indices are within bounds
                valid_start = max(1, min(start_dynamic, signal_length));
                valid_end = max(valid_start, min(end_dynamic, signal_length));
                
                % Apply trimming
                temp_data.(offset_field) = data.(field)(valid_start:valid_end);
            end
        end
    end
    
    % Extract the base name and remove the "x" if present
    [~, baseName, ~] = fileparts(mat_files(i).name);
    if startsWith(baseName, 'x')
        baseName(1) = []; % Remove leading "x"
    end
    
    % Create a valid file name and save the extracted signals to a new .mat file
    save_name = [baseName, '.mat'];
    save_file = fullfile(output_folder, save_name);
    save(save_file, '-struct', 'temp_data');
    fprintf('File saved: %s\n', save_file);
end

fprintf('Extraction complete. %d files processed.\n', length(mat_files));
fprintf('Extracted signals saved in: %s\n', output_folder);