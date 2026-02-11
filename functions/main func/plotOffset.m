function plotOffset(file1, file2, threshold)
    run1 = load(file1);
    run2 = load(file2);

    figure('Name','Pot 1 2');
    
    % Front Left
    x1 = subplot(4,1,1);
    plotAlignedPot(run1.fl_pot_travel_distance, run2.fl_pot_travel_distance, threshold, 'Front Left');

    % Front Right
    x2 = subplot(4,1,2);
    plotAlignedPot(run1.fr_pot_travel_distance, run2.fr_pot_travel_distance, threshold, 'Front Right');

    % Rear Left
    x3 = subplot(4,1,3);
    plotAlignedPot(run1.rl_pot_travel_distance, run2.rl_pot_travel_distance, threshold, 'Rear Left');

    % Rear Right
    x4 = subplot(4,1,4);
    plotAlignedPot(run1.rr_pot_travel_distance, run2.rr_pot_travel_distance, threshold, 'Rear Right');

    linkaxes([x1,x2,x3,x4],'x')
end

function plotAlignedPot(run1, run2, threshold, titleStr)
    n = 100;
    t1 = run1.time;
    y1 = ((run1.signals.values) - (run1.signals.values(1))) /n;
    t2 = run2.time;
    y2 = ((run2.signals.values) - (run2.signals.values(1)))/ n;

    % Inline offset detection logic
    idx1 = find(abs(y1 - y1(1)) > threshold, 1, 'first');
    idx2 = find(abs(y2 - y2(1)) > threshold, 1, 'first');
    if isempty(idx1), idx1 = 1; end
    if isempty(idx2), idx2 = 1; end

    t1a = t1 - t1(idx1);
    t2a = t2 - t2(idx2);

    hold on;
    plot(t1a, y1, t2a, y2);
    ylabel('Travel (mm)');
    title([titleStr ' Pot']);
    legend('Run 1','Run 2','Location','northeast');
    xlim([-5,80]) % change this sometimes 
end
