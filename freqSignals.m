% Script para determinar a frequencia do sinal dos potenciometros
addpath('Pot_data\15-03 Damper test filter\')
fname = '2025-03-15_16-07-39_2_IIB.mat';
data = load(fname);

names = fieldnames(data); % vetor com nomes das variaveis de data
isPot = contains(names, '_pot_travel_distance_offset'); %verifica na cell names se há pot_travel distance (0's e 1's)
pot_names = names(isPot); % guarda os numa cell 

% Percorrer cada sinal e calcular frequencia de amostra ou sampling (fs)
for iPot = 1:numel(pot_names)
    fldName = pot_names{iPot};
    signalData = data.(fldName);
    
    % extrair tempo e sinais
    time = signalData.time;               % em segundos
    values = signalData.signals.values;  % sinal do potenciometro
    
    % converter para vector coluna se necessário
    time = time(:);
    
    % calcular dt e Fs
    dt = diff(time);
    %Fs = 1 ./(dt); % instantâneo 
    Fs = 1 / mean(dt); %média

    % Frequencia de Nyquist - Não é usado para o PSD, mas ajuda para
    % confirmar o limite do nyquist
    F_nyquist = Fs / 2; % qualquer freq acima do F_nyquist vai sofrer aliasing 
    
    % print do resultados
    fprintf('  %s: F_amostra = %.2f Hz\n',fldName, Fs);
    fprintf('  %s: F_nyquist = %.2f Hz\n',fldName, F_nyquist);
     
    % plot dos pot
    plot_pot(iPot) = subplot(2,2,iPot); 
    plot(time,values/100)
    xlabel('Tempo (s)');
    ylabel('Sinal (mm)')
    linkaxes(plot_pot, 'x')
end

% Power Spectral Density    
for iPot = 1: numel(pot_names)
    pot_channel = data.(pot_names{iPot});
    values = pot_channel.signals.values(:);
    time = pot_channel.time(:); 
    
    Fs = 76.65; % o valor da freq de amostra calculado acima
    limite = 25;
    [Pxx, f] = pwelch(values, [],[],[], Fs);
    
    figure(2);
    sync_axes2 = subplot(2,2,iPot);
    %plot(f, Pxx)
    plot(f, 10*log10(Pxx));
    xline([limite;F_nyquist]); yline(0,'--r')
    xlabel('Frequência (Hz)')
    % ylabel('PSD (dB/Hz)')
    linkaxes(sync_axes2, 'x');
end

%% Teste

