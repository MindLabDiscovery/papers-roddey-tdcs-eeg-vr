%% build_supplementary_table.m
%
%  Reproduces Claudia's supplementary table format from the regression
%  family computed in fig_04_gamma_pow_coh_win_nr_all_freq_temp.m.
%
%  Requires in workspace:
%    - p_sum (2080 x 7) — built by the regression loop with kin_idx_list = 1:13
%    - all the dynamically-named _eeg and _kin variables from that script
%
%  Output: supp_table (MATLAB table) + supp_table.csv

%% --- Display labels (match Claudia's table conventions) ---------------

FOI_label   = {'Delta','Theta','Alpha','Beta','Gamma'};
kin_lbl     = {'movementDuration','reactionTime','handpathlength','avgVelocity', ...
               'maxVelocity','velocityPeaks','timetoMaxVel','timetoMaxVeln', ...
               'avgAcceleration','maxAcceleration','accuracy','normalizedjerk','IOC'};
kin_display = {'Movement Duration','Reaction Time','Hand Path Length','Avg Velocity', ...
               'Max Velocity','Velocity Peaks','Time to Max Velocity','Time to Max Velocity (norm)', ...
               'Avg Acceleration','Max Acceleration','Accuracy','Normalized Jerk','IOC'};
phase_int   = {'hold_prep','Prep_Reach'};       % internal naming (matches _eeg/_kin vars)
phase_disp  = {'Hold Prep','Prep Reach'};       % display naming
dz          = {'stroke','healthy'};
stim_status = {'Stim','Sham'};
time_int    = {'pre','i05','i15','pos'};
time_disp   = {'Pre','i5','i15','Post'};
group_disp  = {'CS Stim','CS Sham','HC Stim','HC Sham'};   % indexed by (k-1)*2 + l

%% --- Filter to raw p < 0.05 ------------------------------------------

sig_idx = find(p_sum(:,7) < 0.05);
fprintf('Filtering %d raw-significant rows out of %d total.\n', ...
        numel(sig_idx), size(p_sum,1));

%% --- Build the table -------------------------------------------------

nSig = numel(sig_idx);
Group       = strings(nSig,1);
Time        = strings(nSig,1);
Band        = strings(nSig,1);
PhaseDiff   = strings(nSig,1);
Variable1   = strings(nSig,1);
Metric      = strings(nSig,1);
Variable2   = strings(nSig,1);
PValue      = nan(nSig,1);

for ii = 1:nSig
    r = sig_idx(ii);
    f      = p_sum(r,1);
    kin_id = p_sum(r,2);
    p_id   = p_sum(r,3);
    k      = p_sum(r,4);
    l      = p_sum(r,5);
    t      = p_sum(r,6);
    pval   = p_sum(r,7);

    % Resolve internal variable names
    FOI      = FOI_label{f};
    kinName  = kin_lbl{kin_id};
    phaseInt = phase_int{p_id};
    dzName   = dz{k};
    stimName = stim_status{l};
    timeName = time_int{t};

    % Reconstruct the dynamic _eeg and _kin variable names
    baseName = sprintf('%s_%s_c3c4_diff_%s_%s_%s', ...
                       FOI, kinName, phaseInt, dzName, stimName);
    eegVar = [baseName, '_eeg'];
    kinVar = [baseName, '_kin'];

    % Pull the relevant timepoint column from each, compute mean change
    % (vs. pre) to determine direction of effect (the "arrows")
    eegData = evalin('base', eegVar);     % nSub x 4
    kinData = evalin('base', kinVar);     % nSub x 4

    % Direction of the EEG (coherence-diff) at this timepoint vs. baseline
    eegChange = mean(eegData(:,t), 'omitnan') - mean(eegData(:,1), 'omitnan');
    if t == 1
        % "Pre" is the baseline itself; arrow indicates sign of the diff value
        eegChange = mean(eegData(:,t), 'omitnan');
    end

    % Direction of the kinematic at this timepoint vs. baseline
    kinChange = mean(kinData(:,t), 'omitnan') - mean(kinData(:,1), 'omitnan');
    if t == 1
        kinChange = mean(kinData(:,t), 'omitnan');
    end

    % Fill in the row
    Group(ii)     = group_disp{(k-1)*2 + l};
    Time(ii)      = time_disp{t};
    Band(ii)      = FOI;
    PhaseDiff(ii) = phase_disp{p_id};
    Variable1(ii) = ternary(eegChange >= 0, '↑', '↓');
    Metric(ii)    = kin_display{kin_id};
    Variable2(ii) = ternary(kinChange >= 0, '↑', '↓');
    PValue(ii)    = pval;
end

supp_table = table(Group, Time, Band, PhaseDiff, Variable1, Metric, Variable2, PValue, ...
    'VariableNames', {'Group','TimePeriod','Band','CoherenceDiff', ...
                      'Variable1','Metric','Variable2','PValue'});

%% --- Sort to match Claudia's grouping (by Group, then Time, then Band) ---

group_order = {'CS Sham','CS Stim','HC Sham','HC Stim'};
time_order  = {'Pre','i5','i15','Post'};
band_order  = {'Delta','Theta','Alpha','Beta','Gamma'};

supp_table.GroupKey = categorical(supp_table.Group, group_order, 'Ordinal', true);
supp_table.TimeKey  = categorical(supp_table.TimePeriod, time_order, 'Ordinal', true);
supp_table.BandKey  = categorical(supp_table.Band, band_order, 'Ordinal', true);
supp_table = sortrows(supp_table, {'GroupKey','TimeKey','BandKey'});
supp_table.GroupKey = [];
supp_table.TimeKey  = [];
supp_table.BandKey  = [];

%% --- Display and save -----------------------------------------------

disp(supp_table);

writetable(supp_table, 'supp_table_regenerated.csv');
fprintf('\nSaved: supp_table_regenerated.csv (%d rows)\n', height(supp_table));

%% --- Helper ----------------------------------------------------------

function out = ternary(cond, a, b)
    if cond, out = string(a); else, out = string(b); end
end
