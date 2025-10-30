import { useEffect, useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Coins, Zap, TrendingUp } from 'lucide-react';

interface AnimatedMinerProps {
  tier: 'BASIC' | 'ADVANCED' | 'ELITE';
  miningPower: number;
  tokenId: number;
  isStaked: boolean;
  pendingRewards: string;
}

interface Token {
  id: number;
  x: number;
  y: number;
}

export default function AnimatedMiner({ 
  tier, 
  miningPower, 
  tokenId, 
  isStaked,
  pendingRewards 
}: AnimatedMinerProps) {
  const [tokens, setTokens] = useState<Token[]>([]);
  const [tokenCounter, setTokenCounter] = useState(0);

  // Different colors and speeds for each tier
  const tierConfig = {
    BASIC: {
      color: 'from-gray-400 to-gray-600',
      glow: 'shadow-gray-500/50',
      speed: 3000,
      image: '/nft-artwork/basic-miner.png',
      particles: 1
    },
    ADVANCED: {
      color: 'from-blue-400 to-blue-600',
      glow: 'shadow-blue-500/50',
      speed: 2000,
      image: '/nft-artwork/advanced-miner.png',
      particles: 2
    },
    ELITE: {
      color: 'from-purple-400 to-purple-600',
      glow: 'shadow-purple-500/50',
      speed: 1000,
      image: '/nft-artwork/elite-miner.png',
      particles: 3
    }
  };

  const config = tierConfig[tier];

  // Generate tokens periodically when staked
  useEffect(() => {
    if (!isStaked) return;

    const interval = setInterval(() => {
      const newTokens: Token[] = [];
      for (let i = 0; i < config.particles; i++) {
        newTokens.push({
          id: tokenCounter + i,
          x: Math.random() * 100 - 50,
          y: 0
        });
      }
      setTokens(prev => [...prev, ...newTokens]);
      setTokenCounter(prev => prev + config.particles);

      // Remove old tokens after animation
      setTimeout(() => {
        setTokens(prev => prev.filter(t => !newTokens.find(nt => nt.id === t.id)));
      }, 2000);
    }, config.speed);

    return () => clearInterval(interval);
  }, [isStaked, config.particles, config.speed, tokenCounter]);

  return (
    <div className="relative w-full h-80 bg-gradient-to-b from-background to-accent/20 rounded-lg border-2 border-primary/30 overflow-hidden">
      {/* Background grid */}
      <div className="absolute inset-0 bg-[linear-gradient(to_right,#80808012_1px,transparent_1px),linear-gradient(to_bottom,#80808012_1px,transparent_1px)] bg-[size:24px_24px]" />
      
      {/* Tier badge - top left */}
      <div className="absolute top-3 left-3 bg-background/90 backdrop-blur-sm border-2 border-primary rounded-lg px-3 py-1 text-xs font-bold z-10">
        {tier}
      </div>

      {/* Token ID - top right */}
      <div className="absolute top-3 right-3 bg-background/90 backdrop-blur-sm border border-border rounded-lg px-3 py-1 text-xs font-mono z-10">
        #{tokenId}
      </div>

      {/* Status indicator - bottom right */}
      <div className="absolute bottom-3 right-3 z-10">
        {isStaked ? (
          <motion.div
            className="flex items-center gap-1 bg-green-500/20 text-green-500 px-2 py-1 rounded-full text-xs font-bold backdrop-blur-sm"
            animate={{
              opacity: [1, 0.6, 1],
            }}
            transition={{
              duration: 2,
              repeat: Infinity,
            }}
          >
            <TrendingUp className="w-3 h-3" />
            MINING
          </motion.div>
        ) : (
          <div className="bg-gray-500/20 text-gray-500 px-2 py-1 rounded-full text-xs font-bold backdrop-blur-sm">
            IDLE
          </div>
        )}
      </div>
      
      {/* Miner Machine */}
      <div className="absolute inset-0 flex flex-col items-center justify-center pt-8">
        {/* Main machine image */}
        <motion.div
          className="relative w-48 h-48"
          animate={isStaked ? {
            scale: [1, 1.05, 1],
            y: [0, -5, 0],
          } : {}}
          transition={{
            duration: 2,
            repeat: isStaked ? Infinity : 0,
            ease: "easeInOut"
          }}
        >
          <img 
            src={config.image} 
            alt={`${tier} Miner`}
            className="w-full h-full object-contain drop-shadow-2xl"
          />
        </motion.div>

        {/* Mining power indicator */}
        <div className="mt-4 flex items-center gap-2 text-sm bg-background/80 backdrop-blur-sm px-3 py-1 rounded-full border border-border">
          <Zap className="w-4 h-4 text-primary" />
          <span className="font-mono font-bold">{miningPower}x Power</span>
        </div>

        {/* Pending rewards */}
        {isStaked && (
          <motion.div
            className="mt-2 flex items-center gap-2 text-sm bg-primary/10 backdrop-blur-sm px-3 py-1.5 rounded-full border border-primary/30"
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
          >
            <Coins className="w-4 h-4 text-primary" />
            <span className="font-mono font-bold">{pendingRewards} $FAIR</span>
          </motion.div>
        )}
      </div>

      {/* Animated tokens */}
      <AnimatePresence>
        {tokens.map((token) => (
          <motion.div
            key={token.id}
            className="absolute left-1/2 top-1/2"
            initial={{
              x: token.x,
              y: 0,
              scale: 0,
              opacity: 1,
            }}
            animate={{
              y: -150,
              scale: [0, 1, 1, 0],
              opacity: [0, 1, 1, 0],
            }}
            exit={{
              opacity: 0,
            }}
            transition={{
              duration: 2,
              ease: "easeOut",
            }}
          >
            <Coins className="w-6 h-6 text-primary" />
          </motion.div>
        ))}
      </AnimatePresence>

      {/* Particle effects background */}
      {isStaked && (
        <div className="absolute inset-0 pointer-events-none">
          {[...Array(5)].map((_, i) => (
            <motion.div
              key={i}
              className="absolute w-1 h-1 bg-primary/30 rounded-full"
              style={{
                left: `${Math.random() * 100}%`,
                top: `${Math.random() * 100}%`,
              }}
              animate={{
                scale: [0, 1, 0],
                opacity: [0, 1, 0],
              }}
              transition={{
                duration: 3,
                repeat: Infinity,
                delay: i * 0.5,
              }}
            />
          ))}
        </div>
      )}
    </div>
  );
}
