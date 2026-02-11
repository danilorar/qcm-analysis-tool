function damperHistograms(file1, file2, numBins, numTicks, plotStyle)

    limit = 25;  % limit for low-speed vs high-speed

    % main func calling for file 1 2 
    processFile(file1, 'Run 1', numBins, numTicks, limit, 1, plotStyle);
    processFile(file2, 'Run 2', numBins, numTicks, limit, 2, plotStyle);
end

function processFile(filename, label, numBins, numTicks, limit, figNum, plotStyle) % main func
    
    data = load(filename);  % variables are stored in the 'data' struct
    
    potData     = {'fl_pot_travel_distance_offset', 'fr_pot_travel_distance_offset', 'rl_pot_travel_distance_offset', 'rr_pot_travel_distance_offset'}; % labelling 1x4 
    cornerNames = {'Front Left', 'Front Right', 'Rear Left', 'Rear Right'};
    numCorners  = numel(potData);  % 4
    
    velocities = cell(1, numCorners);% prealocar vector vel 
    
    % Velocity 
    for i = 1:numCorners
        pos = (data.(potData{i}).signals.values - data.(potData{i}).signals.values(1)) / 100;
        dt  = data.(potData{i}).time;
        velocities{i} = gradient(pos) ./ gradient(dt);
    end

    % Bin edges
    velocityCol = cell2mat(velocities(:));
    dataAbsMax  = max(abs(velocityCol));
    binEdges    = linspace(-dataAbsMax, dataAbsMax, numBins+1);
     
    % Plot
    figure('Name', ['Histogram' num2str(figNum)]);
    hold on;
    colors = lines(numCorners); % use 'lines' to color each quadrant
     
    for i = 1:numCorners
        plotDamperHistogram(velocities{i}, binEdges, limit, numTicks, colors(i,:), cornerNames{i}, plotStyle, label);
    end
    
    legend('show');
    hold off; 
end

function plotDamperHistogram(damperData, binEdges, limit, numTicks, color, legendLabel, plotStyle, fileLabel) % histogram func

    if strcmpi(plotStyle, 'bar')
        histogram(damperData, binEdges, 'Normalization', 'probability', 'DisplayStyle', 'stairs', 'EdgeColor', color, 'DisplayName', legendLabel); % condition for either bar or line plot style

    elseif strcmpi(plotStyle, 'line')
        [counts, edges] = histcounts(damperData, binEdges, 'Normalization', 'probability');
        binCenters = (edges(1:end-1) + edges(2:end)) / 2;
        plot(binCenters, counts, 'Color', color, 'DisplayName', legendLabel);
    end

    xlabel('Damper Velocity (mm/s)');
    ylabel('Probability');
    xTicks = linspace(binEdges(1), binEdges(end), numTicks);
    set(gca, 'XTick', xTicks);

    % disp vertical line for hs vs ls
    xline(limit, '--', 'Bump', 'LabelHorizontalAlignment','right');
    xline(-limit, '--', 'Rebound', 'LabelHorizontalAlignment','left');

    % Time spent in each setting
    lsBump    = (sum(damperData >= 0 & damperData < limit) / numel(damperData)) * 100;
    hsBump   = (sum(damperData > limit) / numel(damperData)) * 100;
    lsRebound = (sum(damperData < 0 & damperData > -limit) / numel(damperData)) * 100;
    hsRebound= (sum(damperData < -limit) / numel(damperData)) * 100;
    
    lsDiff  = lsBump - lsRebound;
    hsDiff = hsBump - hsRebound;
    lsAvg   = (lsBump + lsRebound) / 2;
    hsAvg  = (lsBump + hsBump) / 2;
    
    fprintf('=== %s - %s === (%%)\n', fileLabel, legendLabel); % print table
    fprintf('%-12s %8s %9s %12s %8s\n', 'Speed', 'Bump', 'Rebound', 'Difference', 'Average');
    fprintf('----------------------------------------------------\n');
    fprintf('%-12s %8.2f %9.2f %12.2f %8.2f\n', 'Low-Speed', lsBump, lsRebound, lsDiff, lsAvg);
    fprintf('%-12s %8.2f %9.2f %12.2f %8.2f\n\n', 'High-Speed', hsBump, hsRebound, hsDiff, hsAvg);
end

