import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { ConnectWallet } from "@/components/ConnectWallet";
import { Coins, Shield, TrendingUp, Zap, Lock, Users } from "lucide-react";
import { APP_TITLE } from "@/const";

export default function Home() {
  return (
    <div className="min-h-screen bg-gradient-to-b from-background via-background to-muted">
      {/* Header */}
      <header className="border-b border-border/40 backdrop-blur-sm sticky top-0 z-50 bg-background/80">
        <div className="container mx-auto px-4 py-4 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Coins className="h-8 w-8 text-primary" />
            <h1 className="text-2xl font-bold">{APP_TITLE}</h1>
          </div>
          <nav className="hidden md:flex items-center gap-6">
            <a href="#features" className="text-sm hover:text-primary transition-colors">Features</a>
            <a href="#tokenomics" className="text-sm hover:text-primary transition-colors">Tokenomics</a>
            <a href="#miners" className="text-sm hover:text-primary transition-colors">Miners</a>
            <a href="#privacy" className="text-sm hover:text-primary transition-colors">Privacy</a>
          </nav>
          <ConnectWallet />
        </div>
      </header>

      {/* Hero Section */}
      <section className="container mx-auto px-4 py-20 md:py-32">
        <div className="max-w-4xl mx-auto text-center space-y-8">
          <div className="inline-block px-4 py-2 bg-primary/10 border border-primary/20 rounded-full text-sm font-medium text-primary mb-4">
            Fair Launch on Aerodrome • Base Blockchain
          </div>
          <h2 className="text-5xl md:text-7xl font-bold tracking-tight">
            Provably Fair
            <br />
            <span className="text-primary">Bitcoin Mining</span>
            <br />
            Game
          </h2>
          <p className="text-xl text-muted-foreground max-w-2xl mx-auto">
            Stake NFT miners to earn $FAIR tokens. 99.5% of revenue goes back to token holders. 
            Built on Base for low fees and maximum transparency.
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Button size="lg" className="text-lg px-8 py-6">
              Buy Miners
            </Button>
            <Button size="lg" variant="outline" className="text-lg px-8 py-6">
              Start Staking
            </Button>
          </div>
          
          {/* Stats */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-6 pt-12">
            <div className="space-y-2">
              <div className="text-3xl font-bold text-primary">1B</div>
              <div className="text-sm text-muted-foreground">Total Supply</div>
            </div>
            <div className="space-y-2">
              <div className="text-3xl font-bold text-primary">70%</div>
              <div className="text-sm text-muted-foreground">Initial Liquidity</div>
            </div>
            <div className="space-y-2">
              <div className="text-3xl font-bold text-primary">99.5%</div>
              <div className="text-sm text-muted-foreground">Revenue to Holders</div>
            </div>
            <div className="space-y-2">
              <div className="text-3xl font-bold text-primary">5,000</div>
              <div className="text-sm text-muted-foreground">NFT Miners</div>
            </div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section id="features" className="container mx-auto px-4 py-20">
        <div className="text-center mb-16">
          <h3 className="text-3xl md:text-4xl font-bold mb-4">Why $FAIR?</h3>
          <p className="text-muted-foreground text-lg max-w-2xl mx-auto">
            The only truly fair crypto mining game where the community comes first
          </p>
        </div>
        
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6 max-w-6xl mx-auto">
          <Card className="border-border/50 bg-card/50 backdrop-blur-sm">
            <CardHeader>
              <Shield className="h-12 w-12 text-primary mb-4" />
              <CardTitle>Provably Fair</CardTitle>
              <CardDescription>
                All mining calculations on-chain and verifiable. No hidden mechanics or manipulation.
              </CardDescription>
            </CardHeader>
          </Card>

          <Card className="border-border/50 bg-card/50 backdrop-blur-sm">
            <CardHeader>
              <TrendingUp className="h-12 w-12 text-primary mb-4" />
              <CardTitle>Revenue Sharing</CardTitle>
              <CardDescription>
                99.5% of NFT sales revenue distributed to all $FAIR token holders. You benefit from ecosystem growth.
              </CardDescription>
            </CardHeader>
          </Card>

          <Card className="border-border/50 bg-card/50 backdrop-blur-sm">
            <CardHeader>
              <Zap className="h-12 w-12 text-primary mb-4" />
              <CardTitle>Low Fees</CardTitle>
              <CardDescription>
                Built on Base blockchain for lightning-fast transactions with minimal gas fees.
              </CardDescription>
            </CardHeader>
          </Card>

          <Card className="border-border/50 bg-card/50 backdrop-blur-sm">
            <CardHeader>
              <Lock className="h-12 w-12 text-primary mb-4" />
              <CardTitle>Optional Privacy</CardTitle>
              <CardDescription>
                Use our privacy pool for anonymous transactions. You control your privacy level.
              </CardDescription>
            </CardHeader>
          </Card>

          <Card className="border-border/50 bg-card/50 backdrop-blur-sm">
            <CardHeader>
              <Users className="h-12 w-12 text-primary mb-4" />
              <CardTitle>Community First</CardTitle>
              <CardDescription>
                No VC pre-sales. 70% fair launch on Aerodrome. Everyone gets equal access.
              </CardDescription>
            </CardHeader>
          </Card>

          <Card className="border-border/50 bg-card/50 backdrop-blur-sm">
            <CardHeader>
              <Coins className="h-12 w-12 text-primary mb-4" />
              <CardTitle>Sustainable Rewards</CardTitle>
              <CardDescription>
                4-year emission schedule with sigmoid curve prevents hyperinflation and rewards long-term holders.
              </CardDescription>
            </CardHeader>
          </Card>
        </div>
      </section>

      {/* Miners Section */}
      <section id="miners" className="container mx-auto px-4 py-20 bg-muted/30">
        <div className="text-center mb-16">
          <h3 className="text-3xl md:text-4xl font-bold mb-4">NFT Miners</h3>
          <p className="text-muted-foreground text-lg max-w-2xl mx-auto">
            Choose your mining power. Stake to earn $FAIR tokens.
          </p>
        </div>

        <div className="grid md:grid-cols-3 gap-8 max-w-5xl mx-auto">
          {/* Basic Miner */}
          <Card className="border-2 border-border hover:border-primary/50 transition-colors">
            <CardHeader>
              <div className="text-sm font-medium text-muted-foreground mb-2">TIER 1</div>
              <CardTitle className="text-2xl">Basic Miner</CardTitle>
              <div className="text-4xl font-bold text-primary mt-4">10,000</div>
              <div className="text-sm text-muted-foreground">$FAIR</div>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="space-y-2">
                <div className="flex justify-between">
                  <span className="text-sm text-muted-foreground">Mining Power</span>
                  <span className="font-medium">1.0x</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm text-muted-foreground">Max Supply</span>
                  <span className="font-medium">2,500</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm text-muted-foreground">Available</span>
                  <span className="font-medium text-green-500">2,500</span>
                </div>
              </div>
              <Button className="w-full" variant="outline">
                Purchase Basic
              </Button>
            </CardContent>
          </Card>

          {/* Advanced Miner */}
          <Card className="border-2 border-primary shadow-lg shadow-primary/20 scale-105">
            <CardHeader>
              <div className="flex items-center justify-between mb-2">
                <div className="text-sm font-medium text-primary">TIER 2</div>
                <div className="px-2 py-1 bg-primary text-primary-foreground text-xs font-bold rounded">
                  BEST VALUE
                </div>
              </div>
              <CardTitle className="text-2xl">Advanced Miner</CardTitle>
              <div className="text-4xl font-bold text-primary mt-4">30,000</div>
              <div className="text-sm text-muted-foreground">$FAIR</div>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="space-y-2">
                <div className="flex justify-between">
                  <span className="text-sm text-muted-foreground">Mining Power</span>
                  <span className="font-medium">2.5x</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm text-muted-foreground">Max Supply</span>
                  <span className="font-medium">1,500</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm text-muted-foreground">Available</span>
                  <span className="font-medium text-green-500">1,500</span>
                </div>
              </div>
              <Button className="w-full">
                Purchase Advanced
              </Button>
            </CardContent>
          </Card>

          {/* Elite Miner */}
          <Card className="border-2 border-border hover:border-primary/50 transition-colors">
            <CardHeader>
              <div className="text-sm font-medium text-muted-foreground mb-2">TIER 3</div>
              <CardTitle className="text-2xl">Elite Miner</CardTitle>
              <div className="text-4xl font-bold text-primary mt-4">75,000</div>
              <div className="text-sm text-muted-foreground">$FAIR</div>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="space-y-2">
                <div className="flex justify-between">
                  <span className="text-sm text-muted-foreground">Mining Power</span>
                  <span className="font-medium">5.0x</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm text-muted-foreground">Max Supply</span>
                  <span className="font-medium">1,000</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-sm text-muted-foreground">Available</span>
                  <span className="font-medium text-green-500">1,000</span>
                </div>
              </div>
              <Button className="w-full" variant="outline">
                Purchase Elite
              </Button>
            </CardContent>
          </Card>
        </div>
      </section>

      {/* Tokenomics Section */}
      <section id="tokenomics" className="container mx-auto px-4 py-20">
        <div className="text-center mb-16">
          <h3 className="text-3xl md:text-4xl font-bold mb-4">Tokenomics</h3>
          <p className="text-muted-foreground text-lg max-w-2xl mx-auto">
            Transparent distribution designed for long-term sustainability
          </p>
        </div>

        <div className="grid md:grid-cols-2 gap-8 max-w-4xl mx-auto">
          <Card>
            <CardHeader>
              <CardTitle>Token Distribution</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="flex justify-between items-center">
                <span>Aerodrome Liquidity</span>
                <span className="font-bold text-primary">70%</span>
              </div>
              <div className="flex justify-between items-center">
                <span>Mining Rewards (4 years)</span>
                <span className="font-bold text-primary">20%</span>
              </div>
              <div className="flex justify-between items-center">
                <span>Development (2y vesting)</span>
                <span className="font-bold">5%</span>
              </div>
              <div className="flex justify-between items-center">
                <span>Marketing (1y vesting)</span>
                <span className="font-bold">3%</span>
              </div>
              <div className="flex justify-between items-center">
                <span>Community Treasury</span>
                <span className="font-bold">2%</span>
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Emission Schedule</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="flex justify-between items-center">
                <span>Year 1 Daily</span>
                <span className="font-bold">50,000 $FAIR</span>
              </div>
              <div className="flex justify-between items-center">
                <span>Year 2 Daily</span>
                <span className="font-bold text-primary">150,000 $FAIR</span>
              </div>
              <div className="flex justify-between items-center">
                <span>Year 3 Daily</span>
                <span className="font-bold">100,000 $FAIR</span>
              </div>
              <div className="flex justify-between items-center">
                <span>Year 4 Daily</span>
                <span className="font-bold">250,000 $FAIR</span>
              </div>
              <div className="pt-3 border-t border-border">
                <div className="text-sm text-muted-foreground">
                  Sigmoid curve protects against early inflation and rewards long-term holders
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      </section>

      {/* Privacy Section */}
      <section id="privacy" className="container mx-auto px-4 py-20 bg-muted/30">
        <div className="max-w-4xl mx-auto">
          <Card className="border-primary/20 bg-gradient-to-br from-card to-primary/5">
            <CardHeader className="text-center">
              <Lock className="h-16 w-16 text-primary mx-auto mb-4" />
              <CardTitle className="text-3xl">Optional Privacy Pool</CardTitle>
              <CardDescription className="text-lg">
                Protect your transaction privacy while earning protocol revenue
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="grid md:grid-cols-2 gap-6">
                <div className="space-y-2">
                  <h4 className="font-semibold">How It Works</h4>
                  <ul className="space-y-2 text-sm text-muted-foreground">
                    <li>• Deposit $FAIR tokens into privacy pool</li>
                    <li>• Receive private commitment for withdrawal</li>
                    <li>• Withdraw to any address anonymously</li>
                    <li>• Break the link between deposits and withdrawals</li>
                  </ul>
                </div>
                <div className="space-y-2">
                  <h4 className="font-semibold">Fees (Protocol Revenue)</h4>
                  <ul className="space-y-2 text-sm text-muted-foreground">
                    <li>• Deposit fee: 1% (you earn this!)</li>
                    <li>• Withdrawal fee: 0.5% (you earn this!)</li>
                    <li>• Minimum deposit: 100 $FAIR</li>
                    <li>• All fees go to protocol owner</li>
                  </ul>
                </div>
              </div>
              <Button className="w-full" size="lg">
                Use Privacy Pool
              </Button>
            </CardContent>
          </Card>
        </div>
      </section>

      {/* CTA Section */}
      <section className="container mx-auto px-4 py-20">
        <div className="max-w-4xl mx-auto text-center space-y-8 bg-gradient-to-br from-primary/10 to-primary/5 border border-primary/20 rounded-2xl p-12">
          <h3 className="text-4xl font-bold">Ready to Start Mining?</h3>
          <p className="text-xl text-muted-foreground">
            Connect your wallet and join the fairest crypto mining game on Base
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <ConnectWallet />
            <Button size="lg" variant="outline" className="text-lg px-8 py-6">
              Read Documentation
            </Button>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t border-border/40 bg-muted/30">
        <div className="container mx-auto px-4 py-12">
          <div className="grid md:grid-cols-4 gap-8">
            <div className="space-y-4">
              <div className="flex items-center gap-2">
                <Coins className="h-6 w-6 text-primary" />
                <span className="font-bold">{APP_TITLE}</span>
              </div>
              <p className="text-sm text-muted-foreground">
                Provably fair virtual Bitcoin mining on Base blockchain
              </p>
            </div>
            <div className="space-y-3">
              <h4 className="font-semibold">Product</h4>
              <ul className="space-y-2 text-sm text-muted-foreground">
                <li><a href="#" className="hover:text-primary transition-colors">Buy Miners</a></li>
                <li><a href="#" className="hover:text-primary transition-colors">Stake</a></li>
                <li><a href="#" className="hover:text-primary transition-colors">Privacy Pool</a></li>
                <li><a href="#" className="hover:text-primary transition-colors">Dashboard</a></li>
              </ul>
            </div>
            <div className="space-y-3">
              <h4 className="font-semibold">Resources</h4>
              <ul className="space-y-2 text-sm text-muted-foreground">
                <li><a href="#" className="hover:text-primary transition-colors">Documentation</a></li>
                <li><a href="#" className="hover:text-primary transition-colors">Whitepaper</a></li>
                <li><a href="#" className="hover:text-primary transition-colors">Audit Report</a></li>
                <li><a href="#" className="hover:text-primary transition-colors">GitHub</a></li>
              </ul>
            </div>
            <div className="space-y-3">
              <h4 className="font-semibold">Community</h4>
              <ul className="space-y-2 text-sm text-muted-foreground">
                <li><a href="#" className="hover:text-primary transition-colors">Twitter</a></li>
                <li><a href="#" className="hover:text-primary transition-colors">Discord</a></li>
                <li><a href="#" className="hover:text-primary transition-colors">Telegram</a></li>
                <li><a href="#" className="hover:text-primary transition-colors">Medium</a></li>
              </ul>
            </div>
          </div>
          <div className="mt-12 pt-8 border-t border-border/40 text-center text-sm text-muted-foreground">
            <p>© 2025 {APP_TITLE}. All rights reserved. Built on Base blockchain.</p>
          </div>
        </div>
      </footer>
    </div>
  );
}
