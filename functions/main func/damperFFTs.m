function damperFFTs(file1, file2)
    % log run 
    run1 = load(file1);
    run2 = load(file2);
    
    % Run 1 
    figure('Name','FFT 1'); hold on;
    plotFFT(run1.fl_pot_travel_distance, 'FL');
    plotFFT(run1.fr_pot_travel_distance, 'FR');
    plotFFT(run1.rl_pot_travel_distance, 'RL');
    plotFFT(run1.rr_pot_travel_distance, 'RR');
    xlabel('Frequency [Hz]');
    ylabel('Velocity Amplitude');
    legend('show');
    
    % Run 2
    figure('Name','FFT 2'); hold on;
    plotFFT(run2.fl_pot_travel_distance_offset, 'FL');
    plotFFT(run2.fr_pot_travel_distance_offset, 'FR');
    plotFFT(run2.rl_pot_travel_distance_offset, 'RL');
    plotFFT(run2.rr_pot_travel_distance_offset, 'RR');
    xlabel('Frequency [Hz]');
    ylabel('Velocity Amplitude');
    legend('show');
end

function plotFFT(potData, label)
    % Velocity 
    velocity = gradient((potData.signals.values/100)-(potData.signals.values(1)/100)) ./ gradient(potData.time);
    velocity_noDC = velocity - mean(velocity);
    %velocity_noDC = potData.signals.values/100 - mean((potData.signals.values/100)); % if displacement is plotted instead 
    
    % FFT 
    N = length(velocity_noDC);
    Y = fft(velocity_noDC, N);
    
    % Compute one-sided amplitude spectrum 
    Y_mag = abs(Y(1:floor(N/2)+1)) * (2/N);
    
    % Create frequency axis 
    dt = mean(diff(potData.time));
    Fs = 1/dt;
    freq = (0:floor(N/2)) * (Fs/N);
    
    % Plot 
    plot(freq, Y_mag, 'DisplayName', label);
end
