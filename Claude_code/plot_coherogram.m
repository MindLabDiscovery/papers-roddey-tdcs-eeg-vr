%% plot_coherogram.m
%
% PURPOSE
%   Render interhemispheric C3-C4 imaginary coherence across the full
%   frequency axis, rather than as a single band average.
%
%   The band-averaged result cannot distinguish a discrete peak in low
%   gamma from a broader elevation that happens to overlap it. That is the
%   same question the flattened-peak analysis raised, where FlatPeak_Hz
%   came back pinned at exactly 50.0 Hz for three of five participants --
%   the signature of a spectrum ending rather than a feature. Plotting
%   coherence against frequency answers it directly.
%
% INPUT
%   coh_spectra.csv, written by recompute_coherence_multiband.m with
%   SAVE_SPECTRA = true. One row per subject x block x phase x frequency.
%
% OUTPUT
%   coherogram_spectra.png    coherence vs frequency, CS active vs sham,
%                             one panel per block, one row per phase
%   coherogram_diff.png       active minus sham, same layout, with the
%                             band of interest shaded
%   coherogram_values.csv     group means per frequency bin
%
% READING THESE FIGURES
%   A discrete peak in 25-45 Hz that is present in active and absent in
%   sham supports a band-specific effect. A separation that is broad across
%   frequency, or that grows monotonically toward the upper limit of the
%   axis, indicates something other than a narrowband phenomenon and would
%   weaken the band-specific interpretation.
%
% R2019b safe.

clear; clc; close all;

%% ============================ CONFIG ============================
SPEC_PATH = fullfile(pwd,'coh_spectra.csv');
OUT_DIR   = fullfile(pwd,'coherogram_out');
if ~exist(OUT_DIR,'dir'); mkdir(OUT_DIR); end

BAND_SHADE = [25 45];      % the reported band
FMAX_PLOT  = 50;           % upper limit shown; set higher if available
phases   = {'Hold','Prep','Move'};
blockLbl = {'BL','ES','LS','Post'};

CRED = [0.80 0.20 0.20]; CGRY = [0.45 0.45 0.45];

%% ============================ LOAD ==============================
if ~isfile(SPEC_PATH)
    error(['%s not found. Run recompute_coherence_multiband.m with ' ...
           'SAVE_SPECTRA = true.'], SPEC_PATH);
end
S = readtable(SPEC_PATH,'Delimiter',',');
for v = {'subject','group','condition','block','phase'}
    S.(v{1}) = cellstr(string(S.(v{1})));
end
fprintf('Loaded %d rows, %d frequency bins (%.2f-%.2f Hz)\n', ...
    height(S), numel(unique(S.freq)), min(S.freq), max(S.freq));

f = unique(S.freq); f = f(f<=FMAX_PLOT);
nF = numel(f);

% G.(cond){block,phase} = subjects x freq
G = struct();
for cnd = {'Stim','Sham'}
    cn = cnd{1};
    A = cell(4,3);
    subs = unique(S.subject(strcmp(S.group,'CS')&strcmp(S.condition,cn)),'stable');
    for b = 1:4
        for p = 1:3
            M = nan(numel(subs), nF);
            for k = 1:numel(subs)
                m = strcmp(S.subject,subs{k}) & strcmp(S.block,blockLbl{b}) & ...
                    strcmp(S.phase,phases{p});
                if ~any(m); continue; end
                sub = S(m,:);
                [~,loc] = ismember(f, sub.freq);
                v = nan(1,nF);
                v(loc>0) = sub.icoh(loc(loc>0));
                M(k,:) = v;
            end
            A{b,p} = M;
        end
    end
    G.(cn) = A;
    fprintf('  CS %s: n=%d\n', cn, numel(subs));
end

%% ==================== FIG 1: spectra ============================
fh = figure('Position',[30 30 1300 720],'Visible','off');
sp = 0; allv = [];
for p = 1:3
    for b = 1:4
        allv = [allv; mean(G.Stim{b,p},1,'omitnan')'; ...
                      mean(G.Sham{b,p},1,'omitnan')']; %#ok<AGROW>
    end
end
allv = allv(isfinite(allv));
yl = [min(allv)-0.05*range(allv), max(allv)+0.10*range(allv)];

for p = 1:3
    for b = 1:4
        sp = sp+1; subplot(3,4,sp); hold on
        mS = mean(G.Stim{b,p},1,'omitnan'); eS = semrow(G.Stim{b,p});
        mH = mean(G.Sham{b,p},1,'omitnan'); eH = semrow(G.Sham{b,p});
        band_(f, mS, eS, CRED); band_(f, mH, eH, CGRY);
        plot(f, mS, 'Color',CRED,'LineWidth',1.6);
        plot(f, mH, 'Color',CGRY,'LineWidth',1.6);
        ylim(yl); shade_(BAND_SHADE, [0.95 0.90 0.55]);
        xlim([min(f) FMAX_PLOT]); grid on; set(gca,'FontSize',8);
        if p==1; title(blockLbl{b},'FontSize',10); end
        if b==1; ylabel(sprintf('%s\nimaginary coherence',phases{p}),'FontSize',9); end
        if p==3; xlabel('Hz','FontSize',9); end
        if sp==1; legend({'','','CS active','CS sham'},'Location','best','FontSize',7); end
    end
end
sgt('Coherogram: C3-C4 imaginary coherence vs frequency, chronic stroke (mean \pm SEM; 25-45 Hz shaded)');
savefig_both(fh, fullfile(OUT_DIR,'coherogram_spectra.png'));

%% ==================== FIG 2: difference =========================
fh = figure('Position',[30 30 1300 720],'Visible','off');
sp = 0; dall = [];
for p = 1:3
    for b = 1:4
        dall = [dall; (mean(G.Stim{b,p},1,'omitnan') - ...
                       mean(G.Sham{b,p},1,'omitnan'))']; %#ok<AGROW>
    end
end
dall = dall(isfinite(dall)); dl = max(abs(dall))*1.15;

for p = 1:3
    for b = 1:4
        sp = sp+1; subplot(3,4,sp); hold on
        d = mean(G.Stim{b,p},1,'omitnan') - mean(G.Sham{b,p},1,'omitnan');
        % per-frequency two-sample test, shown as marker ticks
        pv = nan(1,nF);
        for q = 1:nF
            a = G.Stim{b,p}(:,q); h = G.Sham{b,p}(:,q);
            pv(q) = tt2p(a,h);
        end
        plot(f, d, 'Color',[0.15 0.30 0.75],'LineWidth',1.5);
        plot([min(f) FMAX_PLOT],[0 0],'k--','HandleVisibility','off');
        sig = pv < 0.05;
        if any(sig)
            plot(f(sig), repmat(dl*0.88,1,sum(sig)), '.', 'Color',[0.8 0 0], ...
                'MarkerSize',6,'HandleVisibility','off');
        end
        ylim([-dl dl]); shade_(BAND_SHADE,[0.95 0.90 0.55]);
        xlim([min(f) FMAX_PLOT]); grid on; set(gca,'FontSize',8);
        if p==1; title(blockLbl{b},'FontSize',10); end
        if b==1; ylabel(sprintf('%s\nactive - sham',phases{p}),'FontSize',9); end
        if p==3; xlabel('Hz','FontSize',9); end
    end
end
sgt(['Coherogram difference: CS active minus sham. Red ticks mark p<.05 per ' ...
     'frequency bin (uncorrected, descriptive only)']);
savefig_both(fh, fullfile(OUT_DIR,'coherogram_diff.png'));

%% ==================== VALUES ====================================
rows = {};
for p = 1:3
    for b = 1:4
        mS = mean(G.Stim{b,p},1,'omitnan'); mH = mean(G.Sham{b,p},1,'omitnan');
        for q = 1:nF
            rows(end+1,:) = {phases{p}, blockLbl{b}, f(q), mS(q), mH(q), ...
                mS(q)-mH(q), tt2p(G.Stim{b,p}(:,q), G.Sham{b,p}(:,q))}; %#ok<AGROW>
        end
    end
end
writetable(cell2table(rows,'VariableNames', ...
    {'Phase','Block','Freq_Hz','mean_active','mean_sham','difference','p'}), ...
    fullfile(OUT_DIR,'coherogram_values.csv'));

fprintf('\nWrote %s\n', OUT_DIR);
fprintf(['\nREAD: in the Move/Post panel, a discrete elevation confined to\n' ...
         '25-45 Hz supports a band-specific effect. A separation that is broad\n' ...
         'across frequency, or that rises steadily toward the top of the axis,\n' ...
         'indicates otherwise and would weaken the band-specific claim.\n' ...
         'Per-frequency tests are uncorrected across %d bins and are shown to\n' ...
         'locate the effect, not to establish it.\n'], nF);

%% ==================== LOCAL FUNCTIONS =========================
function band_(x, m, e, col)
ok = isfinite(m) & isfinite(e);
x=x(ok); m=m(ok); e=e(ok);
if isempty(x); return; end
patch([x(:); flipud(x(:))], [m(:)-e(:); flipud(m(:)+e(:))], col, ...
    'FaceAlpha',0.15,'EdgeColor','none','HandleVisibility','off');
end

function s = semrow(M)
s = nan(1,size(M,2));
for q = 1:size(M,2)
    v = M(:,q); v = v(isfinite(v));
    if numel(v)>1; s(q) = std(v)/sqrt(numel(v)); else; s(q)=0; end
end
end

function p = tt2p(a,b)
a=a(isfinite(a)); b=b(isfinite(b));
if numel(a)<2||numel(b)<2; p=NaN; return; end
se = sqrt(var(a)/numel(a)+var(b)/numel(b));
if se==0; p=NaN; return; end
t=(mean(a)-mean(b))/se;
if exist('ttest2','file')==2
    [~,p] = ttest2(a,b,'Vartype','unequal');
else
    p = 2*(1-0.5*(1+erf(abs(t)/sqrt(2))));
end
end

function shade_(rng,col)
yl = ylim;
patch([rng(1) rng(2) rng(2) rng(1)],[yl(1) yl(1) yl(2) yl(2)],col, ...
    'FaceAlpha',0.25,'EdgeColor','none','HandleVisibility','off');
end

function sgt(txt)
if exist('sgtitle','file'); sgtitle(txt,'FontSize',10);
else
    annotation('textbox',[0 0.95 1 0.05],'String',txt,'EdgeColor','none', ...
        'HorizontalAlignment','center','FontWeight','bold');
end
end

function savefig_both(fh, pngpath)
print(fh, pngpath, '-dpng','-r150');
[d,n,~] = fileparts(pngpath);
try
    print(fh, fullfile(d,[n '.svg']), '-dsvg');
catch
end
close(fh);
end
