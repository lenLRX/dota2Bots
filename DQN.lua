local DQN = {}

DQN.W1 = {}
DQN.B1 = {}

DQN.W2 = {}
DQN.B2 = {}

math.randomseed(RealTime())

DQN.input_dim = 8
DQN.hidden_unit = 100
DQN.output_dim = 3

for i = 0,DQN.input_dim * DQN.hidden_unit - 1,1 do
    DQN.W1[i] = math.random()
end

for i = 0, DQN.hidden_unit - 1, 1 do
    DQN.B1[i] = math.random()
end

for i = 0,DQN.hidden_unit * DQN.output_dim - 1,1 do
    DQN.W2[i] = math.random()
end

for i = 0, DQN.output_dim - 1, 1 do
    DQN.B2[i] = math.random()
end

function DQN:LoadFromTable(tb)
    self.W1 = tb.W1
    self.B1 = tb.B1
    self.W2 = tb.W2
    self.B2 = tb.B2
end

function DQN:ForwardProp(input)
    --print(self)
    --print(self.W1)
    --print(self.hidden_unit)
    local h_out = {}
    for i = 0,self.hidden_unit - 1,1 do
        local s = 0
        for j = 0,self.input_dim - 1,1 do
            s = s + input[j + 1] * self.W1[j * self.hidden_unit + i]
        end
        h_out[i] = s + self.B1[i]
        if h_out[i] < 0 then
            h_out[i] = 0
        end
    end

    local out = {}

    for i = 0,self.output_dim - 1,1 do
        local s = 0
        for j = 0,self.hidden_unit - 1,1 do
            s = s + h_out[j] * self.W2[j * self.output_dim + i]
        end

        out[i] = s + self.B2[i]
    end

    return out
end

function DQN:PrintValidationQ()
    local Q = self:ForwardProp({1, 1, 20000,2000, 1, 1, 0, 0})
    print("validation Q",Q[0],Q[1],Q[2])
end

return DQN