function pta_trace_new = filterPTA(pta_trace)
    % filter out PTAs, remove false pta
    id1s = extractfield(pta_trace,'id1');
    id2s = extractfield(pta_trace,'id2');
    nn = 1;
    while true

        if nn>length(pta_trace)
            break;
        end
        
        if (~ismember(pta_trace(nn).id1, id2s)) && (pta_trace(nn).id1~=1) || ~ismember(pta_trace(nn).id2, id1s)
            pta_trace(nn) = [];
        else
            nn = nn+1;
        end

    end
    pta_trace_new = pta_trace;
    
end

