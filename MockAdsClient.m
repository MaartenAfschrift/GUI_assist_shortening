classdef MockAdsClient < handle
    properties (Access = private)
        handleToSymbol
        storedValues
        startTic
        injectHandleFailure = true
        failHandleToken = 'ModelParameters.MinimalTorque'
    end

    methods
        function obj = MockAdsClient()
            obj.handleToSymbol = containers.Map('KeyType', 'char', 'ValueType', 'char');
            obj.storedValues = containers.Map('KeyType', 'char', 'ValueType', 'double');
            obj.startTic = tic;
        end

        function Connect(~, ~, ~)
            % No-op for offline mode.
        end

        function handle = CreateVariableHandle(obj, symbolName)
            % ponytail: deterministic mock failure to test handle-validation path
            if obj.injectHandleFailure && contains(char(string(symbolName)), obj.failHandleToken)
                error('MockAdsClient:InjectedHandleFailure', ...
                    'Injected handle creation failure for %s', char(string(symbolName)));
            end
            handle = obj.normalizeKey(symbolName);
            obj.handleToSymbol(handle) = handle;
            if ~isKey(obj.storedValues, handle)
                obj.storedValues(handle) = 0;
            end
        end

        function Read(obj, handle, stream)
            symbol = obj.resolveSymbol(handle);
            if contains(symbol, 'gui_output')
                obj.writeDoublesToStream(stream, obj.mockGuiOutputVector());
                return;
            end
            value = obj.mockSignalValue(symbol);
            obj.writeDoublesToStream(stream, value);
        end

        function WriteAny(obj, handle, dataBytes)
            key = obj.resolveSymbol(handle);
            bytes = uint8(dataBytes(:))';
            if numel(bytes) >= 8
                obj.storedValues(key) = typecast(bytes(1:8), 'double');
            end
        end

        function Close(~)
            % No-op for offline mode.
        end
    end

    methods (Access = private)
        function key = resolveSymbol(obj, handle)
            key = obj.normalizeKey(handle);
            if isKey(obj.handleToSymbol, key)
                key = obj.handleToSymbol(key);
            else
                obj.handleToSymbol(key) = key;
                if ~isKey(obj.storedValues, key)
                    obj.storedValues(key) = 0;
                end
            end
        end

        function key = normalizeKey(~, value)
            key = char(string(value));
        end

        function value = mockSignalValue(obj, symbol)
            t = toc(obj.startTic);
            if contains(symbol, 'exo_torque_desired_highlevel_l')
                value = 35 + 8 * sin(2 * pi * 0.7 * t);
            elseif contains(symbol, 'perc_assistance_l')
                value = 20 + 5 * sin(2 * pi * 0.7 * t + 0.4);
            elseif contains(symbol, 'assist_shortening_l')
                value = 12 + 3 * sin(2 * pi * 0.7 * t + 0.9);
            elseif contains(symbol, 'exo_torque_desired_highlevel_r')
                value = 35 + 8 * sin(2 * pi * 0.7 * t + pi);
            elseif contains(symbol, 'perc_assistance_r')
                value = 20 + 5 * sin(2 * pi * 0.7 * t + pi + 0.4);
            elseif contains(symbol, 'assist_shortening_r')
                value = 12 + 3 * sin(2 * pi * 0.7 * t + pi + 0.9);
            elseif contains(symbol, 'tau_sol_l')
                value = 6 + 1.2 * sin(2 * pi * 0.9 * t);
            elseif contains(symbol, 'tau_gas_l')
                value = 8 + 1.5 * sin(2 * pi * 0.9 * t + 0.8);
            elseif contains(symbol, 'tau_tib_l')
                value = -4 + 0.9 * sin(2 * pi * 0.9 * t + 1.5);
            elseif contains(symbol, 'tau_sol_r')
                value = 6 + 1.2 * sin(2 * pi * 0.9 * t + pi);
            elseif contains(symbol, 'tau_gas_r')
                value = 8 + 1.5 * sin(2 * pi * 0.9 * t + pi + 0.8);
            elseif contains(symbol, 'tau_tib_r')
                value = -4 + 0.9 * sin(2 * pi * 0.9 * t + pi + 1.5);
            elseif isKey(obj.storedValues, symbol)
                value = obj.storedValues(symbol);
            else
                value = 0;
            end
        end

        function values = mockGuiOutputVector(obj)
            % ponytail: keep one vector builder to mirror gui_output packing order
            t = toc(obj.startTic);
            values = [
                35 + 8 * sin(2 * pi * 0.7 * t);             % LeftExoDesiredMoment
                35 + 8 * sin(2 * pi * 0.7 * t + pi);        % RightExoDesiredMoment
                20 + 5 * sin(2 * pi * 0.7 * t + 0.4);       % LeftBioMoment
                20 + 5 * sin(2 * pi * 0.7 * t + pi + 0.4);  % RightBioMoment
                12 + 3 * sin(2 * pi * 0.7 * t + 0.9);       % LeftAssistShortMoment
                12 + 3 * sin(2 * pi * 0.7 * t + pi + 0.9);  % RightAssistShortMoment
                6 + 1.2 * sin(2 * pi * 0.9 * t);            % LeftSolMoment
                8 + 1.5 * sin(2 * pi * 0.9 * t + 0.8);      % LeftGasMoment
                -4 + 0.9 * sin(2 * pi * 0.9 * t + 1.5);     % LeftTibMoment
                6 + 1.2 * sin(2 * pi * 0.9 * t + pi);       % RightSolMoment
                8 + 1.5 * sin(2 * pi * 0.9 * t + pi + 0.8); % RightGasMoment
                -4 + 0.9 * sin(2 * pi * 0.9 * t + pi + 1.5);% RightTibMoment
                1                                               % ControlMode
            ];
        end

        function writeDoublesToStream(~, stream, value)
            stream.Position = 0;
            bytes = typecast(double(value(:))', 'uint8');
            netBytes = NET.convertArray(bytes, 'System.Byte');
            stream.Write(netBytes, 0, numel(bytes));
            stream.Position = 0;
        end
    end
end
