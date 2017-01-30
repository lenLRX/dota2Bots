local D2NN = require(GetScriptDirectory().."/DL/D2NN")

--[[
    def create_actor_network(self, state_size, action_dim):
        print("Now we build the Actor model")
        S = Input(shape=[state_size])
        h0 = Dense(HIDDEN1_UNITS, activation='relu')(S)
        h1 = Dense(HIDDEN2_UNITS, activation='relu')(h0)
        Laning = Dense(1, activation='tanh', init=lambda shape,
                       name: normal(shape, scale=1e-4, name=name))(h1)
        Attack = Dense(1, activation='tanh', init=lambda shape,
                       name: normal(shape, scale=1e-4, name=name))(h1)
        Retreat = Dense(1, activation='tanh', init=lambda shape,
                        name: normal(shape, scale=1e-4, name=name))(h1)
        V = merge([Laning, Attack, Retreat], mode='concat')
        model = Model(input=S, output=V)
        return model, model.trainable_weights, S
]]

local ActorDQN = {}
ActorDQN.para = require(GetScriptDirectory().."/data/SFACDQN")

ActorDQN.HIDDEN1_UNITS = 300
ActorDQN.HIDDEN2_UNITS = 600

ActorDQN.h0 = D2NN.FCLayer:new()
ActorDQN.h1 = D2NN.FCLayer:new()

ActorDQN.LaningLayer = D2NN.FCLayer:new()
ActorDQN.AttackLayer = D2NN.FCLayer:new()
ActorDQN.RetreatLayer = D2NN.FCLayer:new()


function ActorDQN:SetUpNetWork()
    local h0w = D2NN.Matrix:new()
    h0w:SetDataShape(self.para.dense_1_W,22,300) 
    local h0b = D2NN.Matrix:new()
    h0b:SetDataShape(self.para.dense_1_B,1,300)

    self.h0:SetW(h0w)
    self.h0:SetB(h0b)
    self.h0:SetActivation(D2NN.Activations.relu)

    local h1w = D2NN.Matrix:new()
    h1w:SetDataShape(self.para.dense_2_W,300,600) 
    local h1b = D2NN.Matrix:new()
    h1b:SetDataShape(self.para.dense_2_B,1,600)

    self.h1:SetW(h1w)
    self.h1:SetB(h1b)
    self.h1:SetActivation(D2NN.Activations.relu)

    local LaningW = D2NN.Matrix:new()
    LaningW:SetDataShape(self.para.Laning_W,600,1)
    local LaningB = D2NN.Matrix:new()
    LaningB:SetDataShape(self.para.Laning_B,1,1)

    self.LaningLayer:SetW(LaningW)
    self.LaningLayer:SetB(LaningB)
    self.LaningLayer:SetActivation(D2NN.Activations.tanh)

    local AttackW = D2NN.Matrix:new()
    AttackW:SetDataShape(self.para.Attack_W,600,1)
    local AttackB = D2NN.Matrix:new()
    AttackB:SetDataShape(self.para.Attack_B,1,1)

    self.AttackLayer:SetW(AttackW)
    self.AttackLayer:SetB(AttackB)
    self.AttackLayer:SetActivation(D2NN.Activations.tanh)

    local RetreatW = D2NN.Matrix:new()
    RetreatW:SetDataShape(self.para.Retreat_W,600,1)
    local RetreatB = D2NN.Matrix:new()
    RetreatB:SetDataShape(self.para.Retreat_B,1,1)

    self.RetreatLayer:SetW(RetreatW)
    self.RetreatLayer:SetB(RetreatB)
    self.RetreatLayer:SetActivation(D2NN.Activations.tanh)
end

function ActorDQN:Predict(input)
    local inputdata = D2NN.Matrix:new()
    inputdata.data = input
    inputdata:SetShape(1, 22)
    
    local h0out = self.h0:ForwardProp(inputdata)
    local h1out = self.h1:ForwardProp(h0out)
    local LaningQ = self.LaningLayer:ForwardProp(h1out).data[0]
    local AttackQ = self.AttackLayer:ForwardProp(h1out).data[0]
    local RetreatQ = self.RetreatLayer:ForwardProp(h1out).data[0]

    return {
        [0] = LaningQ,
        [1] = AttackQ,
        [2] = RetreatQ
        }
end

return ActorDQN