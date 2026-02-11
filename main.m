addpath('Pot_data\15-03 Damper test filter\')
addpath("functions\main func\")

file1 = '2025-03-15_14-26-10_4_IIB.mat';
file2 = '2025-03-15_14-26-10_8_IIB.mat';

%Potentiometers
threshold = 1;
plotOffset(file1, file2, threshold)

%% Damper FFT 
damperFFTs(file1, file2)

% Damper histograms
numBins = 40;  % for nº of bins 
numTicks = 15; % x's increment 
damperHistograms(file1, file2, numBins, numTicks, 'line') % change to 'bar'

%Other signals
plotsignals(file1,file2);


% Roll Stiffness / ratio (RS)
rollsusp = suspotscalc(file1);

    % add function calculate rsd, roll from sus, rg pg, rr 
 
% file ='2025-03-15_18-05-35_14_IIB';
% matfile = fullfile('C:\Users\Legion Slim 5\Desktop\QuarterCar\Pot_data\15-03 damper test', file); disp(matfile)
% [table_csv, accYgVal] = csvExport(matfile, fl_pot_travel_distance, fr_pot_travel_distance, rl_pot_travel_distance, rr_pot_travel_distance, accX, accY, amk_actual_speed0, amk_actual_speed1, amk_actual_speed2, amk_actual_speed3, dash_se, Pitch, Roll, te_main_APPS, te_main_BPSe, te_main_BPSp);

% Modal analysis for wheel loads 
%[force_fl, force_fr, force_rl, force_rr, force_total] = loadsModal(fl_pot_travel_distance.signals.values, fr_pot_travel_distance.signals.values, rl_pot_travel_distance.signals.values,rr_pot_travel_distance.signals.values); 

% table csv to struct
% rollxsensestruct = table2struct(table_csv(:, [14, 20]), 'ToScalar', true);
% rollsusp = table2struct(table_csv(:,[18,19]), 'ToScalar',true);
% rollsusp = [rollsusp.roll_sprung_front, rollsusp.roll_sprung_rear];
