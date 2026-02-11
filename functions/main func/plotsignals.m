function plotsignals(file1, file2)
    
    % Input signals groups and labels
    groups = { {'amk_actual_speed0', 'amk_actual_speed1', 'amk_actual_speed2', 'amk_actual_speed3'}, {'dash_se'}, {'te_main_APPS', 'te_main_BPSe'},{'fl_pot_travel_distance', 'rl_pot_travel_distance'}, {'fr_pot_travel_distance', 'rr_pot_travel_distance'} };
    groupLabels = {'amk_actual_speed', 'Dash_se', 'te_main', 'l_pot_travel_distance', 'r_pot_travel_distance'};

    run1 = load(file1);
    run2 = load(file2);

    plotting(run1,'Run1');
    plotting(run2,'Run2');

    function plotting(file, name)
   
        figure('Name', name);
        
        axesHandles = gobjects(numel(groups), 1); %prelocar mat 5x1
        
        % Loop subplot
        for i = 1:numel(groups)
            ax = subplot(numel(groups), 1, i);
            axesHandles(i) = ax;
            hold(ax, 'on');
            
            currentGroup = groups{i};  %list of signals for this group i=1:5 
            
            for i2 = 1:length(currentGroup) %i2 = 1:5
                signalName = currentGroup{i2};
                if isfield(file, signalName)
                    
                    plot(file.(signalName).time, file.(signalName).signals.values, 'DisplayName', signalName);
                else
                    fprintf('Signal %s not found in file.\n', signalName);
                end
            end
            
            hold off;
            title(groupLabels{i});
            legend('show');
            %xlim([1400, 1540]); % adapt this value for a specific window
        end
        linkaxes(axesHandles, 'x'); % link x axes for zooming and panning
    end
end
