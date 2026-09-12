function run_gamma_topography_test(protocolfolder, outDir)
% RUN_GAMMA_TOPOGRAPHY_TEST
%
% Tests whether the stimulation-related 30-50 Hz increase has a MUSCLE or a
% NEURAL scalp distribution, using the 21-channel montage already recorded.
% Requires no denoising toolbox.
%
% THE LOGIC
%   Scalp EMG (temporalis, frontalis, neck) is maximal at PERIPHERAL
%   electrodes - T3/T4/T5/T6, F7/F8, Fp1/Fp2 - and falls off toward the
%   vertex. Neural sensorimotor gamma does the opposite: maximal at CENTRAL
%   electrodes over hand motor cortex, falling off peripherally.
%
%   The same map is computed for a 70-100 Hz control band, which contains
%   essentially no neural signal at the scalp and therefore shows what a pure
%   muscle/noise topography looks like in this dataset.
%
% THREE OUTCOMES
%   (1) gamma peaks PERIPHERALLY, and its map matches the 70-100 Hz map
%       -> muscle artifact
%   (2) gamma peaks CENTRALLY (C3/C4), map differs from 70-100 Hz
%       -> neural, and worth pursuing
%   (3) gamma uniform across the scalp
%       -> global artifact, reference effect, or stimulation coupling
%
% THE DECISIVE STATISTIC
%   The across-channel correlation between the gamma map and the 70-100 Hz
%   map. If r is high (say > 0.8), the two bands share a generator, and since
%   70-100 Hz cannot be neural at the scalp, neither is the gamma change.
%   This holds regardless of where the peak happens to sit.
%
% USAGE
%   run_gamma_topography_test('D:\...\data_raw','C:\Users\ncr200\Downloads\topo')
%
% OUTPUT
%   <outDir>\topo_<subject>.png        per-subject maps (gamma and control)
%   <outDir>\topo_group.png            group-mean maps
%   <outDir>\gamma_topography.csv      per subject x channel values
%   Console: peripheral-vs-central contrast, radius correlation, and the
%            gamma-vs-control map correlation.

if nargin < 2 || isempty(outDir), outDir = fullfile(pwd,'topo'); end
if ~exist(outDir,'dir'), mkdir(outDir); end

GAMMA = [30 50];
HIGH  = [70 100];

% Label-based classification. Matching is case-insensitive and tolerant of
% common variants (T7/T8 for T3/T4, P7/P8 for T5/T6).
PERIPH = {'T3','T4','T5','T6','T7','T8','P7','P8','F7','F8','FP1','FP2','A1','A2','O1','O2'};
CENTRAL= {'C3','C4','CZ'};

subjects = {
 'pro00087153_0003','C3'
 'pro00087153_0004','C3'
 'pro00087153_0005','C4'
 'pro00087153_0042','C4'
 'pro00087153_0043','C3'
};

blockNames  = {'t1','t2','t3','t4'};
blockLabels = {'BL','ES','LS','Post'};
STIM_BLOCK  = [false true true false];

rows = {};
groupG = []; groupH = []; groupLabels = {}; groupChanlocs = [];

fprintf('Computing per-channel band power across %d subjects...\n\n', size(subjects,1));

for s = 1:size(subjects,1)

    subject = subjects{s,1}; anodeChan = subjects{s,2};
    sid = subject(end-3:end);
    totalFile = fullfile(protocolfolder,subject,'analysis','EEGlab','EEGlab_Total.mat');
    if exist(totalFile,'file')~=2
        fprintf('  %s : MISSING -- skipped\n',subject); continue
    end
    fprintf('  %s (anode %s) ... ', subject, anodeChan);

    try
        S = load(totalFile,'eegevents_tfa');
        if isfield(S,'eegevents_tfa'), ev = S.eegevents_tfa;
        else, S = load(totalFile,'eegevents_ft'); ev = S.eegevents_ft; end
        clear S
    catch ME
        fprintf('LOAD FAILED (%s)\n',ME.message); continue
    end

    % accumulate band power per channel per block (phases concatenated)
    Pg = []; Ph = []; chanlocs = []; labels = {}; srate = NaN; okBlock = false(1,4);

    for b = 1:numel(blockNames)
        if ~isfield(ev.trials,blockNames{b}), continue; end
        wk = ev.trials.(blockNames{b});
        blk = [];
        for p = 1:min(3,size(wk,1))
            peeg = wk(p,:);
            if isempty(peeg) || ~isfield(peeg,'setname') || isempty(peeg.setname), continue; end
            srate = peeg.srate;
            if isempty(chanlocs)
                nch = min(21,numel(peeg.chanlocs));
                chanlocs = peeg.chanlocs(1:nch);
                labels = {chanlocs.labels};
            end
            nch = numel(labels);
            D = double(peeg.data(1:nch,:,:));
            blk = cat(2, blk, reshape(D, nch, []));
        end
        if isempty(blk), continue; end
        okBlock(b) = true;
        for c = 1:size(blk,1)
            Pg(c,b) = bandpow(blk(c,:), srate, GAMMA); %#ok<AGROW>
            Ph(c,b) = bandpow(blk(c,:), srate, HIGH);  %#ok<AGROW>
        end
    end
    clear ev

    if isempty(Pg), fprintf('no data\n'); continue; end

    stimIdx = find(STIM_BLOCK & okBlock);
    restIdx = find(~STIM_BLOCK & okBlock);
    if isempty(stimIdx) || isempty(restIdx)
        fprintf('missing blocks\n'); continue
    end

    dG = mean(Pg(:,stimIdx),2) - mean(Pg(:,restIdx),2);   % gamma stim effect, dB
    dH = mean(Ph(:,stimIdx),2) - mean(Ph(:,restIdx),2);   % control band

    for c = 1:numel(labels)
        rows(end+1,:) = {sid, anodeChan, labels{c}, ...
                         classify_elec(labels{c}, PERIPH, CENTRAL), ...
                         elec_radius(chanlocs(c)), dG(c), dH(c)}; %#ok<AGROW>
    end

    if isempty(groupG)
        groupLabels = labels; groupChanlocs = chanlocs;
        groupG = dG(:); groupH = dH(:);
    elseif numel(labels)==numel(groupLabels) && all(strcmpi(labels,groupLabels))
        groupG = [groupG dG(:)]; groupH = [groupH dH(:)]; %#ok<AGROW>
    else
        fprintf('(montage mismatch - excluded from group mean) ');
    end

    plot_topo_pair(chanlocs, dG, dH, ...
        sprintf('Subject %s  |  anode %s', sid, anodeChan), ...
        fullfile(outDir, sprintf('topo_%s.png', sid)));

    fprintf('done\n');
end

% ---- table --------------------------------------------------------------
T = cell2table(rows,'VariableNames', ...
    {'subject','anode','channel','region','radius','gamma_dB','high_dB'});
csvOut = fullfile(outDir,'gamma_topography.csv');
writetable(T,csvOut);
fprintf('\nWritten: %s (%d rows)\n', csvOut, height(T));

% ---- group figure -------------------------------------------------------
if ~isempty(groupG) && size(groupG,2) > 1
    plot_topo_pair(groupChanlocs, mean(groupG,2), mean(groupH,2), ...
        sprintf('GROUP MEAN (n=%d CS active stim)', size(groupG,2)), ...
        fullfile(outDir,'topo_group.png'));
    fprintf('Written: %s\n', fullfile(outDir,'topo_group.png'));
end

% =========================================================================
% RESULTS
% =========================================================================
fprintf('\n==================================================================\n');
fprintf(' TEST 1 - PERIPHERAL vs CENTRAL (stimulation effect, dB)\n');
fprintf(' Muscle: peripheral > central.  Neural: central > peripheral.\n');
fprintf('==================================================================\n');
fprintf('%-8s %12s %12s %10s %12s %12s\n', ...
        'subject','gamma peri','gamma cent','p-c','high peri','high cent');
subs = unique(T.subject,'stable');
for i = 1:numel(subs)
    ti = T(strcmp(T.subject,subs{i}),:);
    gp = mean(ti.gamma_dB(strcmp(ti.region,'peripheral')));
    gc = mean(ti.gamma_dB(strcmp(ti.region,'central')));
    hp = mean(ti.high_dB(strcmp(ti.region,'peripheral')));
    hc = mean(ti.high_dB(strcmp(ti.region,'central')));
    fprintf('%-8s %+12.2f %+12.2f %+10.2f %+12.2f %+12.2f\n', ...
            subs{i}, gp, gc, gp-gc, hp, hc);
end
gp = mean(T.gamma_dB(strcmp(T.region,'peripheral')));
gc = mean(T.gamma_dB(strcmp(T.region,'central')));
hp = mean(T.high_dB(strcmp(T.region,'peripheral')));
hc = mean(T.high_dB(strcmp(T.region,'central')));
fprintf('%-8s %+12.2f %+12.2f %+10.2f %+12.2f %+12.2f\n','GROUP',gp,gc,gp-gc,hp,hc);

fprintf('\n==================================================================\n');
fprintf(' TEST 2 - DISTANCE FROM VERTEX\n');
fprintf(' Positive r: effect grows toward the periphery => muscle-like.\n');
fprintf('==================================================================\n');
fprintf('%-8s %16s %16s\n','subject','r(gamma,radius)','r(high,radius)');
for i = 1:numel(subs)
    ti = T(strcmp(T.subject,subs{i}),:);
    ok = ~isnan(ti.radius);
    if sum(ok) < 4, fprintf('%-8s %16s %16s\n',subs{i},'no coords','no coords'); continue; end
    rg = corr_simple(ti.radius(ok), ti.gamma_dB(ok));
    rh = corr_simple(ti.radius(ok), ti.high_dB(ok));
    fprintf('%-8s %+16.3f %+16.3f\n', subs{i}, rg, rh);
end

fprintf('\n==================================================================\n');
fprintf(' TEST 3 - DO GAMMA AND THE CONTROL BAND SHARE A TOPOGRAPHY?\n');
fprintf(' High r => same generator. 70-100 Hz cannot be neural at the scalp,\n');
fprintf(' so a high r means the gamma change is not neural either.\n');
fprintf('==================================================================\n');
fprintf('%-8s %24s\n','subject','r(gamma map, high map)');
allr = [];
for i = 1:numel(subs)
    ti = T(strcmp(T.subject,subs{i}),:);
    r = corr_simple(ti.gamma_dB, ti.high_dB);
    allr(end+1) = r; %#ok<AGROW>
    fprintf('%-8s %+24.3f\n', subs{i}, r);
end
fprintf('%-8s %+24.3f\n','MEAN', mean(allr,'omitnan'));

fprintf('\n------------------------------------------------------------------\n');
if mean(allr,'omitnan') > 0.8
    fprintf(' >> Gamma and control maps are nearly identical.\n');
    fprintf('    The 30-50 Hz change is NOT neural in origin.\n');
elseif mean(allr,'omitnan') < 0.4 && gc > gp
    fprintf(' >> Gamma is centrally maximal and spatially distinct from the\n');
    fprintf('    control band. Consistent with a NEURAL effect.\n');
else
    fprintf(' >> Mixed. Inspect the per-subject maps before concluding.\n');
end
fprintf('==================================================================\n');

end % main

% =========================================================================
function p = bandpow(x, fs, band)
x = double(x(:))' - mean(x);
[pxx,f] = pwelch(x, hamming(min(fs,numel(x))), [], [], fs);
p = 10*log10(mean(pxx(f>=band(1) & f<=band(2))) + eps);
end

function r = classify_elec(lbl, PERIPH, CENTRAL)
u = upper(strtrim(lbl));
if any(strcmpi(u,CENTRAL)),     r = 'central';
elseif any(strcmpi(u,PERIPH)),  r = 'peripheral';
else,                           r = 'intermediate';
end
end

function rad = elec_radius(cl)
rad = NaN;
if isfield(cl,'radius') && ~isempty(cl.radius) && isnumeric(cl.radius)
    rad = cl.radius;
elseif isfield(cl,'X') && ~isempty(cl.X) && isfield(cl,'Y') && ~isempty(cl.Y)
    rad = sqrt(double(cl.X)^2 + double(cl.Y)^2);
end
end

function r = corr_simple(x,y)
x = double(x(:)); y = double(y(:));
ok = ~isnan(x) & ~isnan(y);
x = x(ok); y = y(ok);
if numel(x) < 3, r = NaN; return; end
x = x - mean(x); y = y - mean(y);
d = sqrt(sum(x.^2)*sum(y.^2));
if d == 0, r = NaN; else, r = sum(x.*y)/d; end
end

function plot_topo_pair(chanlocs, dG, dH, ttl, outFile)
fh = figure('Color','w','Position',[100 100 1000 430],'Visible','off');
cl = [-1 1] * max([abs(dG(:)); abs(dH(:)); eps]);
for k = 1:2
    subplot(1,2,k);
    if k==1, v = dG; nm = 'low gamma 30-50 Hz';
    else,    v = dH; nm = 'control 70-100 Hz';
    end
    drawn = false;
    if exist('topoplot','file')==2
        try
            topoplot(v, chanlocs, 'electrodes','labels','maplimits',cl);
            drawn = true;
        catch
        end
    end
    if ~drawn
        [xs,ys] = elec_xy(chanlocs);
        scatter(xs, ys, 260, v, 'filled'); hold on
        for c = 1:numel(chanlocs)
            text(xs(c), ys(c), ['  ' chanlocs(c).labels], 'FontSize',7);
        end
        axis equal off; hold off
        caxis(cl);
    end
    colorbar; title(nm,'FontSize',11);
end
annotation(fh,'textbox',[0 0.94 1 0.06],'String', ...
    [ttl '   —   stimulation minus rest (dB); shared colour scale'], ...
    'HorizontalAlignment','center','EdgeColor','none', ...
    'FontSize',12,'FontWeight','bold');
savefig_compat(fh, outFile); close(fh);
end

function [xs,ys] = elec_xy(chanlocs)
n = numel(chanlocs); xs = nan(1,n); ys = nan(1,n);
for c = 1:n
    cl = chanlocs(c);
    if isfield(cl,'X') && ~isempty(cl.X) && isfield(cl,'Y') && ~isempty(cl.Y)
        xs(c) = double(cl.Y); ys(c) = double(cl.X);      % nose up
    elseif isfield(cl,'theta') && ~isempty(cl.theta) && ...
           isfield(cl,'radius') && ~isempty(cl.radius)
        th = double(cl.theta)*pi/180; rr = double(cl.radius);
        xs(c) = rr*sin(th); ys(c) = rr*cos(th);
    end
end
end

function savefig_compat(fh, outFile)
try
    if exist('exportgraphics','file')==2 || exist('exportgraphics','builtin')==5
        exportgraphics(fh, outFile, 'Resolution', 150);
    else
        error('no exportgraphics');
    end
catch
    set(fh,'PaperPositionMode','auto','InvertHardcopy','off','Color','w');
    print(fh, outFile, '-dpng','-r150');
end
end
