import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import AnimatedMiner from '@/components/AnimatedMiner';
import { Coins, TrendingUp, Zap, Wallet } from 'lucide-react';

// Mock data - will be replaced with real blockchain data
const mockStakedMiners = [
  { tokenId: 1, tier: 'BASIC' as const, miningPower: 1, pendingRewards: '125.50' },
  { tokenId: 5, tier: 'ADVANCED' as const, miningPower: 2.5, pendingRewards: '312.75' },
  { tokenId: 12, tier: 'ELITE' as const, miningPower: 5, pendingRewards: '625.00' },
];

const mockUnstakedMiners = [
  { tokenId: 3, tier: 'BASIC' as const, miningPower: 1 },
  { tokenId: 8, tier: 'ADVANCED' as const, miningPower: 2.5 },
];

export default function MiningDashboard() {
  const [selectedTab, setSelectedTab] = useState('staked');

  const totalPendingRewards = mockStakedMiners.reduce(
    (sum, miner) => sum + parseFloat(miner.pendingRewards),
    0
  );

  const totalMiningPower = mockStakedMiners.reduce(
    (sum, miner) => sum + miner.miningPower,
    0
  );

  return (
    <div className="min-h-screen bg-background">
      {/* Header */}
      <header className="border-b border-border bg-card/50 backdrop-blur-sm sticky top-0 z-50">
        <div className="container mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-gradient-to-br from-primary to-primary/60 rounded-lg flex items-center justify-center text-2xl">
                ⚡
              </div>
              <div>
                <h1 className="text-2xl font-bold">Mining Dashboard</h1>
                <p className="text-sm text-muted-foreground">Manage your FAIR miners</p>
              </div>
            </div>
            <Button variant="outline" size="sm">
              <Wallet className="w-4 h-4 mr-2" />
              0x1234...5678
            </Button>
          </div>
        </div>
      </header>

      <div className="container mx-auto px-4 py-8">
        {/* Stats Cards */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
          <Card>
            <CardHeader className="pb-3">
              <CardDescription>Total Pending Rewards</CardDescription>
              <CardTitle className="text-3xl flex items-center gap-2">
                <Coins className="w-6 h-6 text-primary" />
                {totalPendingRewards.toFixed(2)}
              </CardTitle>
            </CardHeader>
            <CardContent>
              <Button className="w-full" size="sm">
                Claim All Rewards
              </Button>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="pb-3">
              <CardDescription>Total Mining Power</CardDescription>
              <CardTitle className="text-3xl flex items-center gap-2">
                <Zap className="w-6 h-6 text-primary" />
                {totalMiningPower}x
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-sm text-muted-foreground">
                {mockStakedMiners.length} miners active
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader className="pb-3">
              <CardDescription>Daily Earnings (Est.)</CardDescription>
              <CardTitle className="text-3xl flex items-center gap-2">
                <TrendingUp className="w-6 h-6 text-primary" />
                ~1,250
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-sm text-muted-foreground">
                Based on current emissions
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Miners Grid */}
        <Tabs value={selectedTab} onValueChange={setSelectedTab}>
          <TabsList className="grid w-full max-w-md grid-cols-2">
            <TabsTrigger value="staked">
              Staked Miners ({mockStakedMiners.length})
            </TabsTrigger>
            <TabsTrigger value="unstaked">
              Unstaked Miners ({mockUnstakedMiners.length})
            </TabsTrigger>
          </TabsList>

          <TabsContent value="staked" className="mt-6">
            {mockStakedMiners.length === 0 ? (
              <Card>
                <CardContent className="flex flex-col items-center justify-center py-12">
                  <div className="text-6xl mb-4">⚙️</div>
                  <h3 className="text-xl font-bold mb-2">No Staked Miners</h3>
                  <p className="text-muted-foreground mb-4">
                    Stake your miners to start earning $FAIR tokens
                  </p>
                  <Button onClick={() => setSelectedTab('unstaked')}>
                    View Unstaked Miners
                  </Button>
                </CardContent>
              </Card>
            ) : (
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                {mockStakedMiners.map((miner) => (
                  <Card key={miner.tokenId} className="overflow-hidden">
                    <CardContent className="p-4">
                      <AnimatedMiner
                        tier={miner.tier}
                        miningPower={miner.miningPower}
                        tokenId={miner.tokenId}
                        isStaked={true}
                        pendingRewards={miner.pendingRewards}
                      />
                      <div className="mt-4 space-y-2">
                        <Button className="w-full" size="sm" variant="outline">
                          Claim Rewards
                        </Button>
                        <Button className="w-full" size="sm" variant="destructive">
                          Unstake Miner
                        </Button>
                      </div>
                    </CardContent>
                  </Card>
                ))}
              </div>
            )}
          </TabsContent>

          <TabsContent value="unstaked" className="mt-6">
            {mockUnstakedMiners.length === 0 ? (
              <Card>
                <CardContent className="flex flex-col items-center justify-center py-12">
                  <div className="text-6xl mb-4">🏪</div>
                  <h3 className="text-xl font-bold mb-2">No Unstaked Miners</h3>
                  <p className="text-muted-foreground mb-4">
                    Purchase miners from the marketplace to start mining
                  </p>
                  <Button>
                    Buy Miners
                  </Button>
                </CardContent>
              </Card>
            ) : (
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                {mockUnstakedMiners.map((miner) => (
                  <Card key={miner.tokenId} className="overflow-hidden">
                    <CardContent className="p-4">
                      <AnimatedMiner
                        tier={miner.tier}
                        miningPower={miner.miningPower}
                        tokenId={miner.tokenId}
                        isStaked={false}
                        pendingRewards="0"
                      />
                      <div className="mt-4">
                        <Button className="w-full" size="sm">
                          Stake Miner
                        </Button>
                      </div>
                    </CardContent>
                  </Card>
                ))}
              </div>
            )}
          </TabsContent>
        </Tabs>

        {/* Info Card */}
        <Card className="mt-8 bg-primary/5 border-primary/20">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Zap className="w-5 h-5" />
              How Mining Works
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-2 text-sm">
            <p>
              <strong>1. Stake your miners</strong> - Transfer your NFT miners to the staking contract to activate them
            </p>
            <p>
              <strong>2. Watch them work</strong> - Your miners will automatically generate $FAIR tokens based on their mining power
            </p>
            <p>
              <strong>3. Claim rewards</strong> - Collect your earned $FAIR tokens anytime
            </p>
            <p className="text-muted-foreground mt-4">
              Mining power: Basic (1x) • Advanced (2.5x) • Elite (5x)
            </p>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
