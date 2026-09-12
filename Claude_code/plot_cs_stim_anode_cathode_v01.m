%% plot_cs_stim_anode_cathode_v01.m
%
% PURPOSE
%   Per-subject ES->LS spectral contrast at the ANODE channel and a
%   comparison channel, for one design cell at a time (default CS active).
%
%   The point is variance, not central tendency: at n=5 a group mean can be
%   produced entirely by one subject, and a real effect should show up as
%   most subjects moving the same way. This script shows every subject
%   individually and prints a numeric table so the pattern can be read
%   without opening a figure.
%
% COMPARISON CHANNEL (set CHAN_MODE)
%   'homolog'  (default) -- contralateral homolog of the anode.
%                C3 anode -> C4 comparison, C4 anode -> C3 comparison.
%                Within-subject control: same electrode type, opposite
%                hemisphere, much weaker field.
%   'ring'     -- explicit surround/return channels for 4x1 HD-tDCS.
%                Fill RING_C3 / RING_C4 with the EEG channels sitting
%                nearest the return electrodes for each anode position.
%                Averaged across the listed channels.
%
% WHAT TO LOOK FOR
%   A current-driven neural effect should be LARGER AT THE ANODE than at
%   the comparison channel, because that is where the field is strongest.
%   An effect of equal size at both is more consistent with something
%   global -- amplifier, reference, or session-wide drift.
%   Note the reference caveat below: with a shared reference, a true focal
%   change leaks into every channel, which SHRINKS anode-vs-comparison
%   differences. So this test is conservative, not decisive.
%
% OUTPUT
%   console table (paste this instead of screenshots)
%   cs_stim_anode_vs_comp.csv
%   fig_subj_<id>_anode_comp.png   per subject
%   fig_overlay_<cell>.png         all subjects overlaid
%
% R2019b safe. No toolboxes required.

clear; clc; close all;

%% ============================ CONFIG ============================
MAT_PATH  = 'C:\Users\ncr200\Downloads\data_raw\subjectData.mat';
OUT_DIR   = fullfile(pwd, 'cs_stim_anode_out');
if ~exist(OUT_DIR,'dir'); mkdir(OUT_DIR); end

TARGET_GROUP = 'CS';        % 'CS' or 'HC'
TARGET_COND  = 'active';    % 'active' or 'sham'

CHAN_MODE = 'homolog';      % 'homolog' | 'ring'
RING_C3 = {};               % e.g. {'F3','T3','P3','Cz'} for a C3 anode
RING_C4 = {};               % e.g. {'F4','T4','P4','Cz'} for a C4 anode

PRIMARY_PHASE = 3;          % 1=hold 2=prep 3=move
TRIAL_ES = 2; TRIAL_LS = 3;

% Bands. reato = the 25-35 Hz window from Reato 2010, added because that is
% where the group-level effect appeared by eye.
bands = { 'drift',[1 4]; 'alpha',[8 13]; 'beta',[13 30]; ...
          'reato',[25 35]; 'gamma',[30 50]; 'control',[70 100] };

FIT_RANGE  = [10 100];
LINE_NOISE = [58 62];
PEAK_RANGE = [25 50];

roster = { '0003','0004','0005','0013','0015','0017','0018','0021','0042','0043', ...
           '0020','0022','0023','0024','0025','0026','0027','0028','0029','0036' };
crf_active = {'0003','0004','0005','0042','0043','0022','0024','0025','0026','0029'};

%% ============================ LOAD ==============================
if ~isfile(MAT_PATH); error('Not found: %s', MAT_PATH); end
S = load(MAT_PATH); sd = S.subjectData; sd_names = {sd.SubjectName};

p1 = sd(1).power;
chanlabels = cell(1,numel(p1.chans));
for c = 1:numel(p1.chans)
    if isfield(p1.chans(c),'labels');    chanlabels{c} = p1.chans(c).labels;
    elseif isfield(p1.chans(c),'label'); chanlabels{c} = p1.chans(c).label;
    else;                                chanlabels{c} = sprintf('ch%d',c); end
end
vals = p1.data(:); vals = vals(isfinite(vals));
IS_DB = mean(vals < 0) > 0.01;
fprintf('Units: %s\n', tern(IS_DB,'already dB','linear -> 10*log10 applied'));
fprintf('Channels: %s\n\n', strjoin(chanlabels,' '));

%% ==================== SELECT SUBJECTS IN CELL ====================
sel = {};
for i = 1:numel(roster)
    sid = roster{i};
    mi = find(contains(sd_names,sid),1);
    if isempty(mi); continue; end
    cond = 'sham'; if any(strcmp(sid,crf_active)); cond = 'active'; end
    grp = 'HC';
    si = sd(mi).sessioninfo;
    if isstruct(si) && isfield(si,'dx') && ~isempty(si.dx) && ...
       strcmpi(strtrim(char(string(si.dx))),'stroke'); grp = 'CS'; end
    if strcmp(grp,TARGET_GROUP) && strcmp(cond,TARGET_COND)
        sel{end+1} = sid; %#ok<SAGROW>
    end
end
fprintf('%s %s: n=%d  (%s)\n\n', TARGET_GROUP, TARGET_COND, numel(sel), strjoin(sel,', '));
if isempty(sel); error('No subjects in that cell.'); end

%% ==================== PER-SUBJECT EXTRACTION ====================
R = struct(); rows = {};

for k = 1:numel(sel)
    sid = sel{k};
    mi  = find(contains(sd_names,sid),1);

    sl = upper(strtrim(char(string(sd(mi).sessioninfo.stimlat))));
    if strcmp(sl,'L'); anode = 'C3'; else; anode = 'C4'; end

    % comparison channel(s)
    switch CHAN_MODE
        case 'homolog'
            comp = {tern(strcmp(anode,'C3'),'C4','C3')};
            comp_name = comp{1};
        case 'ring'
            comp = tern(strcmp(anode,'C3'), RING_C3, RING_C4);
            if isempty(comp)
                error(['CHAN_MODE=''ring'' but RING_C3/RING_C4 are empty. ' ...
                       'Fill them in, or use CHAN_MODE=''homolog''.']);
            end
            comp_name = strjoin(comp,'+');
        otherwise
            error('CHAN_MODE must be ''homolog'' or ''ring''.');
    end

    ia = find(strcmpi(chanlabels,anode),1);
    if isempty(ia); warning('%s: anode %s missing.',sid,anode); continue; end
    ic = [];
    for q = 1:numel(comp)
        j = find(strcmpi(chanlabels,comp{q}),1);
        if ~isempty(j); ic(end+1) = j; end %#ok<SAGROW>
    end
    if isempty(ic); warning('%s: comparison channels missing.',sid); continue; end

    f = squeeze(sd(mi).power.freq(1,:,ia));

    aES = mean(get_spec(sd,mi,ia,PRIMARY_PHASE,TRIAL_ES,IS_DB),2,'omitnan');
    aLS = mean(get_spec(sd,mi,ia,PRIMARY_PHASE,TRIAL_LS,IS_DB),2,'omitnan');

    cES = 0; cLS = 0;
    for j = ic
        cES = cES + mean(get_spec(sd,mi,j,PRIMARY_PHASE,TRIAL_ES,IS_DB),2,'omitnan');
        cLS = cLS + mean(get_spec(sd,mi,j,PRIMARY_PHASE,TRIAL_LS,IS_DB),2,'omitnan');
    end
    cES = cES/numel(ic); cLS = cLS/numel(ic);

    aD = aLS - aES;  cD = cLS - cES;

    aESf = flatten_psd(f,aES,FIT_RANGE,LINE_NOISE);
    aLSf = flatten_psd(f,aLS,FIT_RANGE,LINE_NOISE);
    cESf = flatten_psd(f,cES,FIT_RANGE,LINE_NOISE);
    cLSf = flatten_psd(f,cLS,FIT_RANGE,LINE_NOISE);

    R(k).sid=sid; R(k).anode=anode; R(k).comp=comp_name; R(k).f=f;
    R(k).aES=aES; R(k).aLS=aLS; R(k).aD=aD;
    R(k).cES=cES; R(k).cLS=cLS; R(k).cD=cD;
    R(k).aDf = aLSf-aESf;  R(k).cDf = cLSf-cESf;

    % --- DOUBLE DIFFERENCE: [(LS-ES) anode] - [(LS-ES) comparison] ---
    % Subtracting within each hemisphere first removes the artifact and any
    % session drift common to that electrode; differencing the two residuals
    % then isolates a hemispheric asymmetry in the ES->LS change.
    % Positive = the anodal hemisphere changed MORE over the stimulation
    % period than the comparison hemisphere.
    % NOTE: with a shared reference, a genuinely bilateral effect cancels
    % here. A null is therefore weak evidence; a clear effect is strong.
    R(k).dd  = aD  - cD;      % raw
    R(k).ddf = R(k).aDf - R(k).cDf;   % flattened

    % spectrogram differences (freq x time), for the grid figures
    R(k).aSpecD = get_spec(sd,mi,ia,PRIMARY_PHASE,TRIAL_LS,IS_DB) - ...
                  get_spec(sd,mi,ia,PRIMARY_PHASE,TRIAL_ES,IS_DB);
    cS = 0;
    for j = ic
        cS = cS + (get_spec(sd,mi,j,PRIMARY_PHASE,TRIAL_LS,IS_DB) - ...
                   get_spec(sd,mi,j,PRIMARY_PHASE,TRIAL_ES,IS_DB));
    end
    R(k).cSpecD = cS/numel(ic);
    R(k).t = squeeze(sd(mi).power.times(1,:,ia));

    % band values
    row = {sid, anode, comp_name};
    for b = 1:size(bands,1)
        m = f>=bands{b,2}(1) & f<=bands{b,2}(2);
        row = [row, {mean(aD(m),'omitnan'), mean(cD(m),'omitnan')}]; %#ok<AGROW>
    end
    for b = 1:size(bands,1)
        m = f>=bands{b,2}(1) & f<=bands{b,2}(2);
        row = [row, {mean(R(k).dd(m),'omitnan')}]; %#ok<AGROW>
    end
    pk = f>=PEAK_RANGE(1) & f<=PEAK_RANGE(2);
    [pv,pi_] = max(R(k).aDf(pk)); fp = f(pk);
    row = [row, {pv, fp(pi_), max(R(k).cDf(pk))}];
    rows(end+1,:) = row; %#ok<AGROW>
end
R = R(~cellfun(@isempty,{R.sid}));

%% ==================== CONSOLE TABLE (paste this) ================
fprintf('=== ES->LS change (dB), %s %s ===\n', TARGET_GROUP, TARGET_COND);
fprintf('A = anode channel, C = comparison channel (%s)\n\n', CHAN_MODE);
hdr = sprintf('%-6s %-5s %-7s', 'subj','anod','comp');
for b = 1:size(bands,1)
    hdr = [hdr sprintf(' %8s %8s', [bands{b,1} '.A'], [bands{b,1} '.C'])]; %#ok<AGROW>
end
hdr = [hdr sprintf(' %8s %7s %8s','pkA','pkHz','pkC')];
disp(hdr); disp(repmat('-',1,numel(hdr)));
for i = 1:size(rows,1)
    line = sprintf('%-6s %-5s %-7s', rows{i,1}, rows{i,2}, rows{i,3});
    for b = 1:size(bands,1)
        line = [line sprintf(' %8.3f %8.3f', rows{i,3+2*b-1}, rows{i,3+2*b})]; %#ok<AGROW>
    end
    line = [line sprintf(' %8.3f %7.1f %8.3f', rows{i,end-2}, rows{i,end-1}, rows{i,end})]; %#ok<AGROW>
    disp(line);
end
disp(repmat('-',1,numel(hdr)));
mline = sprintf('%-6s %-5s %-7s','MEAN','','');
for b = 1:size(bands,1)
    va = cellfun(@(x)x, rows(:,3+2*b-1)); vc = cellfun(@(x)x, rows(:,3+2*b));
    mline = [mline sprintf(' %8.3f %8.3f', mean(va,'omitnan'), mean(vc,'omitnan'))]; %#ok<AGROW>
end
disp(mline);

% Consistency: how many subjects move the same direction as the mean?
fprintf('\n=== Direction consistency (n=%d) ===\n', numel(R));
for b = 1:size(bands,1)
    va = cellfun(@(x)x, rows(:,3+2*b-1));
    mu = mean(va,'omitnan');
    fprintf('  %-8s anode mean %+7.3f | %d/%d subjects same sign | range [%+.3f %+.3f]\n', ...
        bands{b,1}, mu, sum(sign(va)==sign(mu)), numel(va), min(va), max(va));
end

% Anode > comparison?
fprintf('\n=== Anode vs comparison (per subject, reato + gamma) ===\n');
ir = find(strcmp(bands(:,1),'reato'));
ig = find(strcmp(bands(:,1),'gamma'));
for i = 1:size(rows,1)
    fprintf('  %-6s reato A %+7.3f C %+7.3f (A-C %+7.3f) | gamma A %+7.3f C %+7.3f (A-C %+7.3f)\n', ...
        rows{i,1}, rows{i,3+2*ir-1}, rows{i,3+2*ir}, rows{i,3+2*ir-1}-rows{i,3+2*ir}, ...
        rows{i,3+2*ig-1}, rows{i,3+2*ig}, rows{i,3+2*ig-1}-rows{i,3+2*ig});
end
fprintf(['\nCAVEAT: with a shared EEG reference, a genuinely focal change leaks\n' ...
         'into all channels, shrinking anode-minus-comparison. A null here is\n' ...
         'weak evidence; a clear anode advantage is strong evidence.\n']);


%% ==================== DOUBLE DIFFERENCE (interhemispheric) ======
% [(LS-ES) at anode] - [(LS-ES) at comparison electrode]
fprintf('\n================================================================\n');
fprintf('  INTERHEMISPHERIC DIFFERENCE IN THE ES->LS CHANGE\n');
fprintf('  [(LS-ES) anode] - [(LS-ES) %s]\n', CHAN_MODE);
fprintf('================================================================\n');
fprintf('Positive = anodal hemisphere changed MORE over the stim period.\n');
fprintf('Artifact common to both electrodes cancels; a shared-reference\n');
fprintf('global effect also cancels, so a null here is weak evidence.\n\n');

hdr2 = sprintf('%-7s', 'subj');
for b = 1:size(bands,1)
    hdr2 = [hdr2 sprintf(' %9s', bands{b,1})]; %#ok<AGROW>
end
disp(hdr2); disp(repmat('-',1,numel(hdr2)));
DD = nan(numel(R), size(bands,1));
for k = 1:numel(R)
    line2 = sprintf('%-7s', R(k).sid);
    for b = 1:size(bands,1)
        m = R(k).f>=bands{b,2}(1) & R(k).f<=bands{b,2}(2);
        DD(k,b) = mean(R(k).dd(m),'omitnan');
        line2 = [line2 sprintf(' %+9.3f', DD(k,b))]; %#ok<AGROW>
    end
    disp(line2);
end
disp(repmat('-',1,numel(hdr2)));
line2 = sprintf('%-7s','MEAN');
for b = 1:size(bands,1)
    line2 = [line2 sprintf(' %+9.3f', mean(DD(:,b),'omitnan'))]; %#ok<AGROW>
end
disp(line2);

fprintf('\n=== Consistency of the hemispheric difference (n=%d) ===\n', numel(R));
fprintf('%-10s %10s %8s %12s %22s\n','band','mean','same sign','t (vs 0)','p');
for b = 1:size(bands,1)
    v = DD(:,b); v = v(isfinite(v));
    mu = mean(v);
    [tv,pv] = ttest1_dd(v);
    fprintf('%-10s %+10.3f %6d/%-2d %12.3f %22.4f\n', ...
        bands{b,1}, mu, sum(sign(v)==sign(mu)), numel(v), tv, pv);
end
fprintf(['\nA hemispheric difference that is consistent in SIGN across\n' ...
         'subjects is more informative than the group mean at n=%d.\n'], numel(R));

%% ==================== CSV =======================================
vn = {'SubjectID','Anode','Comp'};
for b = 1:size(bands,1)
    vn = [vn, {[bands{b,1} '_anode'], [bands{b,1} '_comp']}]; %#ok<AGROW>
end
for b = 1:size(bands,1)
    vn = [vn, {[bands{b,1} '_doublediff']}]; %#ok<AGROW>
end
vn = [vn, {'FlatPeak_anode','FlatPeak_Hz','FlatPeak_comp'}];
writetable(cell2table(rows,'VariableNames',vn), ...
    fullfile(OUT_DIR,'cs_stim_anode_vs_comp.csv'));

%% ==================== FIGURES ===================================
for k = 1:numel(R)
    f = R(k).f;
    fh = figure('Position',[80 80 1250 620],'Visible','off');

    subplot(2,3,1); plot(f,R(k).aES,'k'); hold on; plot(f,R(k).aLS,'r'); grid on;
    xlim([0 max(f)]); ylabel('dB'); legend('ES','LS','Location','best');
    title(sprintf('%s  ANODE %s', R(k).sid, R(k).anode));

    subplot(2,3,2); plot(f,R(k).aD,'b'); hold on; refline0();
    shade(bands{4,2},[0.95 0.9 0.4]); grid on; xlim([0 max(f)]);
    title('anode LS-ES'); ylabel('dB');

    subplot(2,3,3); plot(f,R(k).aDf,'m'); hold on; refline0();
    shade(PEAK_RANGE,[0.85 0.9 1]); grid on; xlim([0 max(f)]);
    title('anode LS-ES, flattened');

    subplot(2,3,4); plot(f,R(k).cES,'k'); hold on; plot(f,R(k).cLS,'r'); grid on;
    xlim([0 max(f)]); xlabel('Hz'); ylabel('dB');
    title(sprintf('COMP %s', R(k).comp));

    subplot(2,3,5); plot(f,R(k).cD,'b'); hold on; refline0();
    shade(bands{4,2},[0.95 0.9 0.4]); grid on; xlim([0 max(f)]); xlabel('Hz');
    title('comp LS-ES');

    subplot(2,3,6); plot(f,R(k).cDf,'m'); hold on; refline0();
    shade(PEAK_RANGE,[0.85 0.9 1]); grid on; xlim([0 max(f)]); xlabel('Hz');
    title('comp LS-ES, flattened');

    % match y-limits across the two difference columns so anode vs comp is
    % visually comparable rather than independently autoscaled
    lim2 = maxabs([R(k).aD; R(k).cD]);
    subplot(2,3,2); ylim([-lim2 lim2]); subplot(2,3,5); ylim([-lim2 lim2]);
    lim3 = maxabs([R(k).aDf; R(k).cDf]);
    subplot(2,3,3); ylim([-lim3 lim3]); subplot(2,3,6); ylim([-lim3 lim3]);

    print(fh, fullfile(OUT_DIR,sprintf('fig_subj_%s_anode_comp.png',R(k).sid)),'-dpng','-r150');
    close(fh);
end

% Overlay: every subject on one axis, so a single driver is obvious.
fh = figure('Position',[80 80 1250 400],'Visible','off');
cols = lines(numel(R));
subplot(1,3,1); hold on;
for k=1:numel(R); plot(R(k).f,R(k).aD,'Color',cols(k,:)); end
refline0(); shade(bands{4,2},[0.95 0.9 0.4]); grid on;
xlim([0 max(R(1).f)]); title('ANODE LS-ES, per subject'); ylabel('dB'); xlabel('Hz');
legend({R.sid},'Location','best','FontSize',7);

subplot(1,3,2); hold on;
for k=1:numel(R); plot(R(k).f,R(k).cD,'Color',cols(k,:)); end
refline0(); shade(bands{4,2},[0.95 0.9 0.4]); grid on;
xlim([0 max(R(1).f)]); title('COMP LS-ES, per subject'); xlabel('Hz');

subplot(1,3,3); hold on;
for k=1:numel(R); plot(R(k).f,R(k).aDf,'Color',cols(k,:)); end
refline0(); shade(PEAK_RANGE,[0.85 0.9 1]); grid on;
xlim([0 max(R(1).f)]); title('ANODE LS-ES flattened, per subject'); xlabel('Hz');

print(fh, fullfile(OUT_DIR,sprintf('fig_overlay_%s_%s.png',TARGET_GROUP,TARGET_COND)),'-dpng','-r150');
close(fh);


%% ---- GRID 1: PSD difference, all subjects, shared scale ----
% Rows = subjects, Cols = [anode, homolog]. Shared y-limits across every
% panel so subject-to-subject magnitude is directly comparable by eye and
% a single driver is immediately visible.
nR = numel(R);
gl = 0;
for k = 1:nR; gl = max([gl, maxabs([R(k).aD; R(k).cD])]); end

fh = figure('Position',[40 40 760 190*nR],'Visible','off');
for k = 1:nR
    f = R(k).f;
    subplot(nR,2,2*k-1); plot(f,R(k).aD,'b','LineWidth',1.1); hold on; refline0();
    shade(bands{4,2},[0.95 0.9 0.4]); grid on;
    xlim([0 max(f)]); ylim([-gl gl]);
    ylabel(sprintf('%s\ndB', R(k).sid),'FontWeight','bold');
    if k==1; title('ANODE  (LS - ES)'); end
    if k==nR; xlabel('Hz'); end
    text(0.98,0.92,R(k).anode,'Units','normalized','HorizontalAlignment','right', ...
        'FontWeight','bold','Color',[0 0 0.7]);

    subplot(nR,2,2*k); plot(f,R(k).cD,'Color',[0.4 0.4 0.4],'LineWidth',1.1); hold on;
    refline0(); shade(bands{4,2},[0.95 0.9 0.4]); grid on;
    xlim([0 max(f)]); ylim([-gl gl]);
    if k==1; title('HOMOLOG  (LS - ES)'); end
    if k==nR; xlabel('Hz'); end
    text(0.98,0.92,R(k).comp,'Units','normalized','HorizontalAlignment','right', ...
        'FontWeight','bold','Color',[0.4 0.4 0.4]);
end
print(fh, fullfile(OUT_DIR,sprintf('GRID_psd_%s_%s.png',TARGET_GROUP,TARGET_COND)),'-dpng','-r150');
close(fh);

%% ---- GRID 2: spectrogram difference, all subjects, shared color scale ----
gc = 0;
for k = 1:nR
    gc = max([gc, maxabs(R(k).aSpecD(:)), maxabs(R(k).cSpecD(:))]);
end
fh = figure('Position',[40 40 820 190*nR],'Visible','off');
for k = 1:nR
    f = R(k).f; t = R(k).t;
    subplot(nR,2,2*k-1); imagesc(t,f,R(k).aSpecD); axis xy; caxis([-gc gc]);
    ylabel(sprintf('%s (%s)\nHz', R(k).sid, R(k).anode),'FontWeight','bold');
    if k==1; title('ANODE  spectrogram LS - ES'); end
    if k==nR; xlabel('time'); end
    colorbar;

    subplot(nR,2,2*k); imagesc(t,f,R(k).cSpecD); axis xy; caxis([-gc gc]);
    if k==1; title('HOMOLOG  spectrogram LS - ES'); end
    if k==nR; xlabel('time'); end
    colorbar;
end
print(fh, fullfile(OUT_DIR,sprintf('GRID_spec_%s_%s.png',TARGET_GROUP,TARGET_COND)),'-dpng','-r150');
close(fh);


%% ---- GRID 3: interhemispheric double difference, all subjects ----
% One curve per subject: [(LS-ES) anode] - [(LS-ES) comparison].
% Shared y-limits so subject-to-subject magnitude is comparable, and the
% group mean overlaid in bold so a consistent hemispheric effect is visible
% against subjects that scatter.
gd = 0;
for k = 1:nR; gd = max([gd, maxabs(R(k).dd)]); end

fh = figure('Position',[40 40 900 480],'Visible','off');

subplot(1,2,1); hold on
cols3 = lines(nR);
M = nan(nR, numel(R(1).f));
for k = 1:nR
    plot(R(k).f, R(k).dd, 'Color',[cols3(k,:) 0.75], 'LineWidth',1.1);
    M(k,:) = R(k).dd(:)';
end
plot(R(1).f, mean(M,1,'omitnan'), 'k', 'LineWidth',2.5);
refline0(); shade(bands{4,2},[0.95 0.9 0.4]);
grid on; xlim([0 max(R(1).f)]); ylim([-gd gd]);
xlabel('Hz'); ylabel('\Delta dB  (anode - comparison)');
title(sprintf('%s %s: interhemispheric difference in ES->LS change', ...
    TARGET_GROUP, TARGET_COND), 'FontSize',9);
legend([{R.sid}, {'mean'}], 'Location','best','FontSize',7);

subplot(1,2,2); hold on
gdf = 0;
for k = 1:nR; gdf = max([gdf, maxabs(R(k).ddf)]); end
Mf = nan(nR, numel(R(1).f));
for k = 1:nR
    plot(R(k).f, R(k).ddf, 'Color',[cols3(k,:) 0.75], 'LineWidth',1.1);
    Mf(k,:) = R(k).ddf(:)';
end
plot(R(1).f, mean(Mf,1,'omitnan'), 'k', 'LineWidth',2.5);
refline0(); shade(PEAK_RANGE,[0.85 0.9 1]);
grid on; xlim([0 max(R(1).f)]); ylim([-gdf gdf]);
xlabel('Hz'); title('same, after aperiodic removal','FontSize',9);

print(fh, fullfile(OUT_DIR,sprintf('GRID_doublediff_%s_%s.png',TARGET_GROUP,TARGET_COND)), ...
    '-dpng','-r150');
close(fh);

fprintf('\nWrote figures + CSV to %s\n', OUT_DIR);
fprintf(['Start with GRID_doublediff_*.png (interhemispheric difference),\n' ...
         'then GRID_psd_*.png and GRID_spec_*.png.\n']);

%% ==================== LOCAL FUNCTIONS ===========================
function [tstat,p] = ttest1_dd(d)
% One-sample t against zero, with a normal-approximation fallback.
d = d(isfinite(d)); n = numel(d);
if n < 2; tstat = NaN; p = NaN; return; end
sd_ = std(d);
if sd_ == 0; tstat = NaN; p = NaN; return; end
tstat = mean(d)/(sd_/sqrt(n));
if exist('ttest','file') == 2
    [~,p] = ttest(d);
else
    p = 2*(1 - 0.5*(1+erf(abs(tstat)/sqrt(2))));
end
end

function sg = get_spec(sd, sidx, ch, phase, trial, is_db)
raw = squeeze(sd(sidx).power.data(:,:,ch,phase,trial));
if is_db; sg = raw; else; sg = 10*log10(raw); end
end

function [flat, ap] = flatten_psd(f, psd, fit_range, line_noise)
f = f(:); psd = psd(:);
m = f>=fit_range(1) & f<=fit_range(2) & isfinite(psd) & f>0;
m = m & ~(f>=line_noise(1) & f<=line_noise(2));
ap = struct('slope',NaN,'intercept',NaN);
if sum(m) < 5; flat = nan(size(psd)); return; end
X = [ones(sum(m),1), log10(f(m))];
b = X \ psd(m);
ap.intercept=b(1); ap.slope=b(2);
pred = nan(size(psd)); v = f>0;
pred(v) = b(1) + b(2)*log10(f(v));
flat = psd - pred;
end

function refline0()
xl = xlim;
plot(xl,[0 0],'k--','LineWidth',0.8,'HandleVisibility','off');
end

function shade(rng,col)
yl = ylim;
patch([rng(1) rng(2) rng(2) rng(1)],[yl(1) yl(1) yl(2) yl(2)],col, ...
    'FaceAlpha',0.22,'EdgeColor','none','HandleVisibility','off');
end

function v = maxabs(x)
v = max(abs(x(isfinite(x))));
if isempty(v) || v==0; v = 1; end
end

function out = tern(c,a,b)
if c; out = a; else; out = b; end
end
