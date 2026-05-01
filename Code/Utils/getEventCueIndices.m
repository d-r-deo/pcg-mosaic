function out = getEventCueIndices(state, participant)

    originalState = state;
    state_OG = state;

    % figure();
    % plot(state,'r*');
    hold on;
    
    indsRet = find(state == 2);
    state(indsRet) = 3;
    
    diffState = [0; diff(state)];
    indsNone = find(diffState == 0);
    diffState(indsNone) = nan;
    indsRet = find(diffState == 2);
    diffState(indsRet) = 3;
    
    indsDel = find(diffState == -3);
    diffState(indsDel) = 0;
    
    indsRet = find(diffState == 3);
    diffState(indsRet) = 2;
   
    % find start of prep trials at beginning of block
    inds_go = find(state_OG == 1);
    inds_ret = find(state_OG == 2);
    inds_del = find(state_OG == 0);
    state_OG(inds_go) = 2; % now go is 2, return is 2 delay is 0
    state_OG(inds_del) = 10;
    indsNan = find(isnan(state_OG) == 1);
    state_OG(indsNan) = 20;
    diffDelEnd = diff(state_OG);
    indsDes = find(diffDelEnd == -10);

    diffState(indsDes) = 0;


    % check for T15 data
    indsCuePresentRogue = find(diffState == -1);
    diffState(indsCuePresentRogue) = 0;
   
    if strcmp(participant,'T15')
        % rogue events for T15
        diff_stateOG = diff(originalState);
        indsRogueReturn = find(diff_stateOG == -1);
        indsRegReturn = find(diffState == 2);
        diffState_two = diffState;
        diffState_toss = diffState;
        diffState_two(indsRogueReturn) = 2;
    
        hold on;
        % plot(diffState_two,'gx');

        retInds = find(diffState_two == 2);
        retThrow = find(ismember(retInds,indsRogueReturn) == 1); % these are the indices to throw of trial codes for return errors
    
        diffState = diffState_two;
        diffState(1) = 0;
    else
        retThrow = [];
    end

     presentCue = find(diffState == 0);
    goCue = find(diffState == 1);
    returnCue = find(diffState == 2);

    if numel(presentCue) > numel(goCue)
        presentCue(end) = [];
    end

    presentThrow = [];
    goThrow = [];

    if strcmp(participant, 'T17') || strcmp(participant, 'T18')
        indsThrow = [];
        presentCue = [1; presentCue];
        itor = 1;
        ret_itor = 1;
        for c = 1 : numel(presentCue)

            if (numel(goCue) < (itor+1)) || (numel(returnCue) < ret_itor)
                break;
            end
            currGo = goCue(itor);
            nextGo = goCue(itor+1);
            currRet = returnCue(ret_itor);

            if ~((currRet > currGo) && (nextGo > currRet))
                indsThrow = [indsThrow itor];
                itor = itor + 1;
            else
                itor = itor + 1;
                ret_itor = ret_itor + 1;
            end


        end
        presentThrow = indsThrow;
        goThrow = indsThrow;

    end


   % plot(diffState,'k^');
    ylim([-3 4]);

    out.presentCue = presentCue;
    out.goCue = goCue;
    out.returnCue = returnCue;
    out.stateTransitions = diffState;
    out.indsThrowTrlCodes_forReturn = retThrow;
    out.indsThrowTrlCodes_forPresent = presentThrow;
    out.indsThrowTrlCodes_forGo = goThrow;

end