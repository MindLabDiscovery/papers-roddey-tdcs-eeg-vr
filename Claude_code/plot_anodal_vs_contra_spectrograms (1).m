function plot_anodal_vs_contra_spectrograms(protocolfolder, outDir)
% PLOT_ANODAL_VS_CONTRA_SPECTROGRAMS
%
% For each chronic stroke ACTIVE STIMULATION subject, plots two spectrograms
% on a SHARED colour scale:
%     top    - anodal channel        (C3 or C4, whichever carried the anode)
%     bottom - contralateral homolog (the opposite central channel)
% across the full session BL -> ES -> LS -> Post.
%
% WHAT THIS TESTS
%   The apparent 30-50 Hz increase during stimulation has three competing
%   explanations, which this figure discriminates between:
%
%     (1) Neural gamma, anodal-specific  -> increase confined to 30-50 Hz AND
%                                           larger on the anodal channel
%     (2) Stimulation/hardware artifact  -> broadband increase, anodal-biased
%     (3) EMG / movement / session state -> broadband increase, BILATERAL
%
%   A band-limited, lateralised increase supports (1). A broadband bilateral
%   increase supports (3) and would not survive review as a gamma finding.
%
% QUANTIFICATION
%   Alongside the figures this writes band_power_comparison.csv containing, for
%   every subject x block x channel, mean power in delta/theta/alpha/beta/gamma
%   plus a HIGH band (70-100 Hz). The high band is the key control: it contains
%   no physiological rhythm of interest, so if it rises with gamma the change is
%   broadband rather than gamma-specific.
%
% USAGE
%   plot_anodal_vs_contra_spectrograms('D:\...\data_raw','C:\...\spectrograms')

if nargin < 2 || isempty(outDir), outDir = fullfile(pwd,'spectrograms'); end
if ~exist(outDir,'dir'), mkdir(outDir); end

subjects = {
 'pro00087153_0003', 'C3', 'R'
 'pro00087153_0004', 'C3', 'R'
 'pro00087153_0005', 'C4', 'L'
 'pro00087153_0042', 'C4', 'L'
 'pro00087153_0043', 'C3', 'R'
};

blockNames  = {'t1','t2','t3','t4'};
blockLabels = {'BL','ES','LS','Post'};

FMAX  = 100;
BANDS = { 'delta',[1 4]; 'theta',[4 8]; 'alpha',[8 12]; ...
          'beta',[13 30]; 'gamma',[30 50]; 'high',[70 100] };

bandRows = {};

for s = 1:size(subjects,1)

    subject   = subjects{s,1};
    anodeChan = subjects{s,2};
    contraChan = ternary(strcmpi(anodeChan,'C3'),'C4','C3');
    sid = subject(end-3:end);

    totalFile = fullfile(protocolfolder,subject,'analysis','EEGlab','EEGlab_Total.mat');
    if exist(totalFile,'file')~=2
        fprintf('  %s : MISSING -- skipped\n',subject); continue
    end
    fprintf('  %s (anode %s, contra %s) ... ',subject,anodeChan,contraChan);

    try
        S = load(totalFile,'eegevents_tfa');
        if isfield(S,'eegevents_tfa'), ev = S.eegevents_tfa;
        else, S = load(totalFile,'eegevents_ft'); ev = S.eegevents_ft; end
        clear S
    catch ME
        fprintf('LOAD FAILED (%s)\n',ME.message); continue
    end

    sigA = []; sigC = []; bounds = []; srate = NaN;
    interpA = false(1,4); interpC = false(1,4); present = false(1,4);

    for b = 1:numel(blockNames)
        if ~isfield(ev.trials,blockNames{b}), continue; end
        wk = ev.trials.(blockNames{b});
        blkA = []; blkC = [];

        for p = 1:min(3,size(wk,1))
            peeg = wk(p,:);
            if isempty(peeg) || ~isfield(peeg,'setname') || isempty(peeg.setname), continue; end

            lbls = {peeg.chanlocs.labels};
            iA = find(strcmpi(lbls,anodeChan),1);
            iC = find(strcmpi(lbls,contraChan),1);
            if isempty(iA) || isempty(iC), continue; end
            srate = peeg.srate;

            bc = [];
            if isfield(peeg,'badChannels') && isfield(peeg.badChannels,'channels')
                tmp = peeg.badChannels.channels;
                if ~any(isnan(tmp(:))), bc = tmp(:)'; end
            end
            if ismember(iA,bc), interpA(b) = true; end
            if ismember(iC,bc), interpC(b) = true; end

            dA = double(squeeze(peeg.data(iA,:,:)));
            dC = double(squeeze(peeg.data(iC,:,:)));
            blkA = [blkA; dA(:)];  %#ok<AGROW>
            blkC = [blkC; dC(:)];  %#ok<AGROW>
        end

        if ~isempty(blkA)
            present(b) = true;
            sigA = [sigA; blkA];  %#ok<AGROW>
            sigC = [sigC; blkC];  %#ok<AGROW>
            bounds(end+1) = numel(sigA); %#ok<AGROW>

            % ---- band power for this block, both channels ----------------
            for ch = 1:2
                if ch==1, x = blkA; chName = anodeChan; role='anodal'; itp=interpA(b);
                else,     x = blkC; chName = contraChan; role='contralateral'; itp=interpC(b);
                end
                [pxx,f] = pwelch(x - mean(x), hamming(srate), srate/2, [], srate);
                pdb = 10*log10(pxx + eps);
                vals = zeros(1,size(BANDS,1));
                for k = 1:size(BANDS,1)
                    rng = BANDS{k,2};
                    vals(k) = mean(pdb(f>=rng(1) & f<=rng(2)));
                end
                bandRows(end+1,:) = [{sid, blockLabels{b}, chName, role, ...
                                      ternary(itp,'YES','no')}, num2cell(vals)]; %#ok<AGROW>
            end
        end
    end
    clear ev

    if isempty(sigA), fprintf('no data\n'); continue; end

    % ---- spectrograms, shared colour scale ------------------------------
    win = round(srate); nov = round(srate*0.5); nfft = 2^nextpow2(srate*2);
    [~,F,T,PA] = spectrogram(sigA - mean(sigA), win, nov, nfft, srate);
    [~,~,~,PC] = spectrogram(sigC - mean(sigC), win, nov, nfft, srate);
    keep = F <= FMAX;
    PAdb = 10*log10(PA(keep,:) + eps);
    PCdb = 10*log10(PC(keep,:) + eps);
    cl = prctile_compat([PAdb(:); PCdb(:)],[5 99]);   % SHARED scale

    fh = figure('Color','w','Position',[100 100 1150 720],'Visible','off');
    idxP = find(present);
    tb = bounds / srate;

    for panel = 1:2
        ax = subplot(2,1,panel);
        if panel==1, D = PAdb; chName = anodeChan; role='ANODAL'; itp = interpA;
        else,        D = PCdb; chName = contraChan; role='CONTRALATERAL'; itp = interpC;
        end
        imagesc(T, F(keep), D); axis xy; caxis(cl); colormap(ax,parula);
        cb = colorbar; cb.Label.String = 'Power (dB)';
        ylabel('Frequency (Hz)');
        if panel==2, xlabel('Concatenated session time (s)'); end

        hold on
        prev = 0;
        for b = 1:numel(tb)
            if b < numel(tb), plot([tb(b) tb(b)],[0 FMAX],'w-','LineWidth',2); end
            mid = (prev + tb(b))/2;
            lbl = blockLabels{idxP(b)};
            flag = ''; if itp(idxP(b)), flag = ' *INTERP*'; end
            text(mid, FMAX*0.93, [lbl flag],'Color','w','FontWeight','bold', ...
                 'HorizontalAlignment','center','FontSize',11);
            prev = tb(b);
        end
        plot(xlim,[30 30],'w--','LineWidth',0.75);
        plot(xlim,[50 50],'w--','LineWidth',0.75);
        plot(xlim,[70 70],'r--','LineWidth',0.75);   % high-band control floor
        hold off

        ib = blockLabels(itp & present);
        if isempty(ib), istr='none'; else, istr=strjoin(ib,', '); end
        title(sprintf('%s channel %s  |  interpolated in: %s', role, chName, istr), ...
              'FontSize',12,'FontWeight','bold','Interpreter','none');
    end

    annotation(fh,'textbox',[0 0.955 1 0.045],'String', ...
        sprintf(['Subject %s  |  CS active stim  |  shared colour scale  |  ' ...
                 'white dashed = gamma 30-50 Hz, red dashed = 70 Hz (high-band control)'], sid), ...
        'HorizontalAlignment','center','EdgeColor','none', ...
        'FontSize',13,'FontWeight','bold');

    outFile = fullfile(outDir, sprintf('spec_anodalVScontra_%s.png', sid));
    savefig_compat(fh, outFile); close(fh);
    fprintf('saved %s\n', outFile);
end

% ---- band power table ---------------------------------------------------
hdr = [{'subject','block','channel','role','interpolated'}, BANDS(:,1)'];
T = cell2table(bandRows,'VariableNames',hdr);
csvOut = fullfile(outDir,'band_power_comparison.csv');
writetable(T,csvOut);
fprintf('\nBand power table: %s (%d rows)\n', csvOut, height(T));

% ---- console: the two decisive contrasts --------------------------------
fprintf('\n=================================================================\n');
fprintf(' TEST 1 - BAND SPECIFICITY: does gamma rise more than the 70-100 Hz\n');
fprintf('          control band? If they move together, the change is broadband.\n');
fprintf('=================================================================\n');
fprintf('%-8s %-6s %-14s %10s %10s %10s\n','subject','block','role','gamma','high','g-h');
subs = unique(T.subject,'stable');
for i = 1:numel(subs)
    ti = T(strcmp(T.subject,subs{i}),:);
    base = ti(strcmp(ti.block,'BL'),:);
    for b = {'ES','LS','Post'}
        for r = {'anodal','contralateral'}
            row = ti(strcmp(ti.block,b{1}) & strcmp(ti.role,r{1}),:);
            bb  = base(strcmp(base.role,r{1}),:);
            if isempty(row) || isempty(bb), continue; end
            dG = row.gamma - bb.gamma;
            dH = row.high  - bb.high;
            fprintf('%-8s %-6s %-14s %+10.2f %+10.2f %+10.2f\n', ...
                subs{i}, b{1}, r{1}, dG, dH, dG-dH);
        end
    end
end

fprintf('\n=================================================================\n');
fprintf(' TEST 2 - LATERALISATION: gamma change anodal minus contralateral.\n');
fprintf('          Near zero => bilateral => not stimulation-specific.\n');
fprintf('=================================================================\n');
fprintf('%-8s %-6s %14s %14s %12s\n','subject','block','d_gamma_anodal','d_gamma_contra','difference');
for i = 1:numel(subs)
    ti = T(strcmp(T.subject,subs{i}),:);
    base = ti(strcmp(ti.block,'BL'),:);
    for b = {'ES','LS','Post'}
        ra = ti(strcmp(ti.block,b{1}) & strcmp(ti.role,'anodal'),:);
        rc = ti(strcmp(ti.block,b{1}) & strcmp(ti.role,'contralateral'),:);
        ba = base(strcmp(base.role,'anodal'),:);
        bc = base(strcmp(base.role,'contralateral'),:);
        if isempty(ra)||isempty(rc)||isempty(ba)||isempty(bc), continue; end
        dA = ra.gamma - ba.gamma;  dC = rc.gamma - bc.gamma;
        fprintf('%-8s %-6s %+14.2f %+14.2f %+12.2f\n', subs{i}, b{1}, dA, dC, dA-dC);
    end
end
fprintf('=================================================================\n');

end

% =========================================================================
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

function y = prctile_compat(x,p)
if exist('prctile','file')==2, y = prctile(x,p); return; end
x = sort(x(:)); n = numel(x);
pos = max(1,min(n,(p(:)/100)*n + 0.5));
lo = floor(pos); hi = ceil(pos); frac = pos - lo;
y = x(lo).*(1-frac) + x(hi).*frac;
y = reshape(y,size(p));
end

function out = ternary(c,a,b)
if c, out = a; else, out = b; end
end
