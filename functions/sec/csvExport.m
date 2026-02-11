function [table_csv,accYgVal] = csvExport(matFile, fl_pot, fr_pot, rl_pot, rr_pot, accX, accY, amk0, amk1, amk2, amk3, dash, pitch, roll, apps, bpse, bpsp)

    % Verifica que ficheiro mat é texto
    if ~ischar(matFile) && ~isstring(matFile)
        error('matFile must be a string or character vector.');
    end

    matFile = char(matFile);  % string to char

    % Extract base name for CSV
    [~, baseName, ~] = fileparts(matFile);
    
    % Remove leading 'x' if present
    if startsWith(baseName, 'x')
        baseName(1) = [];
    end
   
    % Usar comand strrep do basename e tira '_mat'
    baseName = strrep(baseName, '_mat', '');
    
    % Final CSV name
    csvName = [baseName, '.csv'];

    %  Master time (front-left pot)
    masterTime = fl_pot.time;
    flVal      = fl_pot.signals.values;

    % Inline resampling to masterTime
    resampleFn = @(sig) interp1(sig.time, sig.signals.values, masterTime, 'linear', 'extrap');

    % Resample each signal
    frVal    = resampleFn(fr_pot);
    rlVal    = resampleFn(rl_pot);
    rrVal    = resampleFn(rr_pot);
    accXVal  = resampleFn(accX);
    accYVal  = resampleFn(accY);
    amk0Val  = resampleFn(amk0);
    amk1Val  = resampleFn(amk1);
    amk2Val  = resampleFn(amk2);
    amk3Val  = resampleFn(amk3);
    dashVal  = resampleFn(dash); % direita volante é positivo
    pitchVal = resampleFn(pitch);
    rollVal  = resampleFn(roll);
    appsVal  = resampleFn(apps);
    bpseVal  = resampleFn(bpse);
    bpspVal  = resampleFn(bpsp);
    accYgVal = accYVal./9.81;

    % cálculo de roll teórico da sprung 
    mrF = 1.04; mrR = 1.2; track = 1205;
    rollF = -(atan((((flVal/100) - (flVal(1))/100) - ((frVal/100) - (frVal(1))/100)) * mrF / track))* (180/pi());
    rollR = -(atan((((rlVal/100) - (rlVal(1))/100) - ((rrVal/100) - (rrVal(1))/100)) * mrR / track))* (180/pi());
    rollT = -atan(((((flVal/100) - (flVal(1)/100)) - ((frVal/100) - (frVal(1)/100)) ) * mrF + (((rlVal/100) - (rlVal(1)/100)) - ((rrVal/100) - (rrVal(1)/100))) * mrR) / (2*track))* (180/pi);

    % velocidade damper 
    damper_vel_fl = abs(gradient(flVal/100) ./ gradient(masterTime));
    damper_vel_fr = abs(gradient(frVal/100) ./ gradient(masterTime));
    damper_vel_rl = abs(gradient(rlVal/100) ./ gradient(masterTime));
    damper_vel_rr = abs(gradient(rrVal/100) ./ gradient(masterTime));

    % constroi uma table para guardar as variaveis pretendidas (adiciona +)
    table_csv = table(masterTime, accXVal, accYVal, ...
    amk0Val, amk1Val, amk2Val, amk3Val, dashVal, ...
    ((flVal/100)-(flVal(1))/100), ((frVal/100)-(frVal(1))/100), ((rlVal/100)-(rlVal(1))/100), ((rrVal/100)-(rrVal(1))/100), ...
    pitchVal, rollVal,appsVal, bpseVal, bpspVal, rollF, rollR, rollT, ...
    damper_vel_fl, damper_vel_fr, damper_vel_rl, damper_vel_rr, ...
    'VariableNames', {
      'Time_s','accX','accY','amk_actual_speed0','amk_actual_speed1','amk_actual_speed2','amk_actual_speed3',...
      'dash_se','fl_pot_travel_distance','fr_pot_travel_distance','rl_pot_travel_distance','rr_pot_travel_distance','Pitch','Roll',...
      'te_main_APPS','te_main_BPSe','te_main_BPSp','roll_sprung_front','roll_sprung_rear','roll_sprung_total',...
      'damper_vel_fl','damper_vel_fr','damper_vel_rl','damper_vel_rr'});

    writetable(table_csv, csvName); % cria o csv guarda o como csvName

end
