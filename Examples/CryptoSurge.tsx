import React from 'react';

import {
  useCurrentFrame,
  useVideoConfig,
  interpolate,
  Easing,
  AbsoluteFill,
  Sequence,
} from 'remotion';

// =============================================================================
// COMPOSITION CONFIG
// =============================================================================

export const compositionConfig = {
  id: 'CryptoSurge',
  durationInSeconds: 5,
  fps: 60,
  width: 1920,
  height: 1080,
};

// =============================================================================
// STYLE CONSTANTS
// =============================================================================

const COLORS = {
  primary: '#00ff88',
  secondary: '#00c96b',
  accent: '#39ffb0',
  background: '#050908',
  panel: '#09120f',
  grid: '#123126',
  text: '#eafff4',
  muted: '#6d8f81',
  red: '#ff5577',
} as const;

const TYPOGRAPHY = {
  fontFamily: 'Inter, system-ui, sans-serif',
} as const;

const EASINGS = {
  easeOut: Easing.bezier(0.33, 1, 0.68, 1),
  easeInOut: Easing.bezier(0.37, 0, 0.63, 1),
  overshoot: Easing.bezier(0.34, 1.56, 0.64, 1),
};

// =============================================================================
// PRE-GENERATED DATA
// =============================================================================

const seededRandom = (seed: number): number => {
  const x = Math.sin(seed * 9999) * 10000;
  return x - Math.floor(x);
};

const candles = Array.from({ length: 34 }, (_, index) => {
  const base = 20 + index * 2.15 + Math.pow(index / 33, 2.2) * 74;
  const noise = (seededRandom(index + 11) - 0.5) * 5;

  return {
    x: 180 + index * 47,
    open: base + noise,
    close:
      base +
      (seededRandom(index + 31) - 0.5) * 7 +
      (index > 26 ? (index - 26) * 1.2 : 0),
    high: base + 6 + seededRandom(index + 51) * 7,
    low: base - 5 - seededRandom(index + 71) * 6,
  };
});

const chartPoints = [
  [150, 805],
  [205, 790],
  [260, 812],
  [315, 775],
  [370, 790],
  [425, 735],
  [480, 748],
  [535, 690],
  [590, 710],
  [645, 660],
  [700, 675],
  [755, 610],
  [810, 630],
  [865, 555],
  [920, 575],
  [975, 515],
  [1030, 530],
  [1085, 450],
  [1140, 470],
  [1195, 405],
  [1250, 430],
  [1305, 350],
  [1360, 375],
  [1415, 300],
  [1470, 320],
  [1525, 245],
  [1580, 265],
  [1635, 190],
  [1690, 210],
  [1745, 145],
];

const chartPath = chartPoints
  .map(([x, y], index) => `${index === 0 ? 'M' : 'L'} ${x} ${y}`)
  .join(' ');

// =============================================================================
// MAIN COMPONENT
// =============================================================================

const CryptoSurge: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps, durationInFrames, width, height } = useVideoConfig();

  const progress = interpolate(frame, [0, durationInFrames - 18], [0, 1], {
    easing: EASINGS.easeInOut,
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  const introOpacity = interpolate(frame, [0, 28], [0, 1], {
    easing: EASINGS.easeOut,
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  const chartProgress = interpolate(frame, [18, 250], [0, 1], {
    easing: EASINGS.easeOut,
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  const price = interpolate(chartProgress, [0, 1], [0, 1000], {
    easing: EASINGS.easeInOut,
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  const displayPrice = Math.round(price);

  const cameraX = interpolate(frame, [0, durationInFrames], [0, -115], {
    easing: EASINGS.easeInOut,
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  const glowPulse = interpolate(
    Math.sin(frame * 0.16),
    [-1, 1],
    [0.72, 1],
    {
      extrapolateLeft: 'clamp',
      extrapolateRight: 'clamp',
    },
  );

  const gridOpacity = interpolate(frame, [0, 45], [0, 0.45], {
    easing: EASINGS.easeOut,
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  const formatPrice = `$${displayPrice.toLocaleString('en-US')}`;

  return (
    <AbsoluteFill
      style={{
        backgroundColor: COLORS.background,
        color: COLORS.text,
        fontFamily: TYPOGRAPHY.fontFamily,
        overflow: 'hidden',
      }}
    >
      {/* Ambient glow */}
      <AbsoluteFill
        style={{
          background:
            'radial-gradient(circle at 68% 52%, rgba(0,255,136,0.075) 0%, rgba(0,255,136,0.02) 28%, transparent 62%)',
          opacity: glowPulse,
        }}
      />

      {/* Volumetric HUD grid */}
      <AbsoluteFill
        style={{
          opacity: gridOpacity,
          transform: `perspective(900px) rotateX(62deg) scale(1.4) translateY(145px)`,
          transformOrigin: 'center bottom',
          backgroundImage: `
            linear-gradient(rgba(18,49,38,0.65) 1px, transparent 1px),
            linear-gradient(90deg, rgba(18,49,38,0.65) 1px, transparent 1px)
          `,
          backgroundSize: '64px 64px',
          maskImage:
            'linear-gradient(to bottom, transparent 0%, black 35%, black 100%)',
        }}
      />

      {/* Top HUD */}
      <div
        style={{
          position: 'absolute',
          top: 62,
          left: 84,
          right: 84,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          opacity: introOpacity,
        }}
      >
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: 18,
          }}
        >
          <div
            style={{
              width: 12,
              height: 12,
              borderRadius: '50%',
              backgroundColor: COLORS.primary,
              boxShadow: `0 0 18px ${COLORS.primary}`,
            }}
          />
          <div
            style={{
              fontSize: 25,
              fontWeight: 700,
              letterSpacing: 5,
            }}
          >
            NEXUS / TRADE
          </div>
        </div>

        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: 32,
            fontSize: 18,
            color: COLORS.muted,
            letterSpacing: 2,
          }}
        >
          <span>BTC/USD</span>
          <span>LIVE</span>
          <span
            style={{
              color: COLORS.primary,
              textShadow: `0 0 12px ${COLORS.primary}`,
            }}
          >
            ● 60 FPS
          </span>
        </div>
      </div>

      {/* Main chart scene */}
      <div
        style={{
          position: 'absolute',
          inset: 0,
          transform: `translateX(${cameraX}px)`,
        }}
      >
        {/* Chart panel */}
        <div
          style={{
            position: 'absolute',
            left: 105,
            top: 190,
            width: 1710,
            height: 675,
            border: '1px solid rgba(77,153,119,0.18)',
            background:
              'linear-gradient(145deg, rgba(8,20,15,0.72), rgba(4,10,8,0.38))',
            boxShadow: 'inset 0 0 80px rgba(0,255,136,0.018)',
          }}
        />

        {/* Horizontal HUD guides */}
        {[0, 1, 2, 3, 4].map((index) => {
          const y = 245 + index * 125;

          return (
            <div
              key={`guide-${index}`}
              style={{
                position: 'absolute',
                left: 130,
                top: y,
                width: 1660,
                height: 1,
                backgroundColor: 'rgba(50,108,84,0.18)',
              }}
            />
          );
        })}

        {/* Price labels */}
        {[1000, 750, 500, 250, 0].map((value, index) => (
          <div
            key={`price-${value}`}
            style={{
              position: 'absolute',
              left: 139,
              top: 222 + index * 125,
              color: COLORS.muted,
              fontSize: 17,
              letterSpacing: 1,
              opacity: introOpacity,
            }}
          >
            ${value.toLocaleString()}
          </div>
        ))}

        {/* Candlesticks */}
        {candles.map((candle, index) => {
          const candleOpacity = interpolate(
            frame,
            [25 + index * 2, 40 + index * 2],
            [0, 0.72],
            {
              easing: EASINGS.easeOut,
              extrapolateLeft: 'clamp',
              extrapolateRight: 'clamp',
            },
          );

          const isPositive = candle.close >= candle.open;
          const bodyTop = Math.min(candle.open, candle.close);
          const bodyHeight = Math.max(
            Math.abs(candle.close - candle.open),
            5,
          );

          return (
            <div
              key={`candle-${index}`}
              style={{
                position: 'absolute',
                left: candle.x,
                top: 300,
                width: 24,
                height: 500,
                opacity: candleOpacity,
              }}
            >
              <div
                style={{
                  position: 'absolute',
                  left: 11,
                  top: candle.high * 2.35,
                  width: 2,
                  height: Math.max(
                    18,
                    (candle.low - candle.high) * -2.35,
                  ),
                  backgroundColor: isPositive
                    ? 'rgba(0,255,136,0.28)'
                    : 'rgba(255,85,119,0.24)',
                }}
              />

              <div
                style={{
                  position: 'absolute',
                  left: 4,
                  top: bodyTop * 2.35,
                  width: 16,
                  height: bodyHeight * 2.35,
                  backgroundColor: isPositive
                    ? 'rgba(0,255,136,0.18)'
                    : 'rgba(255,85,119,0.15)',
                  border: `1px solid ${
                    isPositive
                      ? 'rgba(0,255,136,0.38)'
                      : 'rgba(255,85,119,0.32)'
                  }`,
                }}
              />
            </div>
          );
        })}

        {/* Chart trail */}
        <svg
          width="1920"
          height="1080"
          viewBox="0 0 1920 1080"
          style={{
            position: 'absolute',
            inset: 0,
            overflow: 'visible',
          }}
        >
          <defs>
            <filter id="chartGlow">
              <feGaussianBlur stdDeviation="10" result="blur" />
              <feMerge>
                <feMergeNode in="blur" />
                <feMergeNode in="SourceGraphic" />
              </feMerge>
            </filter>

            <filter id="softGlow">
              <feGaussianBlur stdDeviation="22" />
            </filter>

            <linearGradient
              id="areaGradient"
              x1="0"
              y1="0"
              x2="0"
              y2="1"
            >
              <stop
                offset="0%"
                stopColor="#00ff88"
                stopOpacity="0.14"
              />
              <stop
                offset="100%"
                stopColor="#00ff88"
                stopOpacity="0"
              />
            </linearGradient>
          </defs>

          {/* Broad volumetric trail */}
          <path
            d={chartPath}
            fill="none"
            stroke="#00ff88"
            strokeWidth="34"
            strokeLinecap="round"
            strokeLinejoin="round"
            opacity="0.045"
            filter="url(#softGlow)"
            pathLength={1}
            strokeDasharray="1"
            strokeDashoffset={1 - chartProgress}
          />

          {/* Sharp light trail */}
          <path
            d={chartPath}
            fill="none"
            stroke="#00ff88"
            strokeWidth="13"
            strokeLinecap="round"
            strokeLinejoin="round"
            opacity="0.16"
            filter="url(#chartGlow)"
            pathLength={1}
            strokeDasharray="1"
            strokeDashoffset={1 - chartProgress}
          />

          {/* Main neon curve */}
          <path
            d={chartPath}
            fill="none"
            stroke="#00ff88"
            strokeWidth="4"
            strokeLinecap="round"
            strokeLinejoin="round"
            filter="url(#chartGlow)"
            pathLength={1}
            strokeDasharray="1"
            strokeDashoffset={1 - chartProgress}
          />

          {/* Area beneath curve */}
          <path
            d={`${chartPath} L 1745 845 L 150 845 Z`}
            fill="url(#areaGradient)"
            opacity={chartProgress * 0.75}
          />

          {/* Leading point */}
          <circle
            cx={150 + (1745 - 150) * chartProgress}
            cy={805 + (145 - 805) * chartProgress}
            r="17"
            fill="#00ff88"
            opacity="0.12"
            filter="url(#softGlow)"
          />

          <circle
            cx={150 + (1745 - 150) * chartProgress}
            cy={805 + (145 - 805) * chartProgress}
            r="6"
            fill="#eafff4"
            stroke="#00ff88"
            strokeWidth="3"
          />
        </svg>

        {/* Current value HUD */}
        <div
          style={{
            position: 'absolute',
            left: 1170,
            top: 240,
            opacity: introOpacity,
          }}
        >
          <div
            style={{
              fontSize: 17,
              color: COLORS.muted,
              letterSpacing: 3,
              margin: 0,
            }}
          >
            ASSET VALUE
          </div>

          <div
            style={{
              margin: 0,
              marginTop: 10,
              fontSize: 74,
              lineHeight: 1,
              fontWeight: 700,
              letterSpacing: -3,
              color: COLORS.text,
              textShadow: `0 0 24px rgba(0,255,136,${0.2 * glowPulse})`,
            }}
          >
            {formatPrice}
          </div>

          <div
            style={{
              margin: 0,
              marginTop: 14,
              fontSize: 21,
              color: COLORS.primary,
              letterSpacing: 2,
            }}
          >
            +{Math.round(chartProgress * 10000) / 100}%
          </div>
        </div>
      </div>

      {/* Bottom status HUD */}
      <Sequence from={55}>
        <div
          style={{
            position: 'absolute',
            left: 84,
            right: 84,
            bottom: 58,
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'flex-end',
            opacity: interpolate(frame, [55, 75], [0, 1], {
              easing: EASINGS.easeOut,
              extrapolateLeft: 'clamp',
              extrapolateRight: 'clamp',
            }),
          }}
        >
          <div
            style={{
              display: 'flex',
              gap: 44,
              color: COLORS.muted,
              fontSize: 16,
              letterSpacing: 1.5,
            }}
          >
            <div>
              <div style={{ margin: 0, color: COLORS.muted }}>
                VOLUME
              </div>
              <div
                style={{
                  margin: 0,
                  marginTop: 7,
                  color: COLORS.text,
                  fontSize: 20,
                }}
              >
                84.21M
              </div>
            </div>

            <div>
              <div style={{ margin: 0, color: COLORS.muted }}>
                MARKET
              </div>
              <div
                style={{
                  margin: 0,
                  marginTop: 7,
                  color: COLORS.primary,
                  fontSize: 20,
                }}
              >
                BULLISH
              </div>
            </div>

            <div>
              <div style={{ margin: 0, color: COLORS.muted }}>
                LATENCY
              </div>
              <div
                style={{
                  margin: 0,
                  marginTop: 7,
                  color: COLORS.text,
                  fontSize: 20,
                }}
              >
                2.4ms
              </div>
            </div>
          </div>

          <div
            style={{
              fontSize: 15,
              color: COLORS.muted,
              letterSpacing: 2,
            }}
          >
            REAL-TIME MARKET DATA / ENCRYPTED
          </div>
        </div>
      </Sequence>

      {/* Scanline */}
      <div
        style={{
          position: 'absolute',
          left: 0,
          right: 0,
          top: interpolate(
            frame,
            [0, durationInFrames],
            [0, height],
            {
              easing: EASINGS.easeInOut,
              extrapolateLeft: 'clamp',
              extrapolateRight: 'clamp',
            },
          ),
          height: 2,
          backgroundColor: 'rgba(0,255,136,0.08)',
          boxShadow: '0 0 25px rgba(0,255,136,0.12)',
        }}
      />
    </AbsoluteFill>
  );
};

export default CryptoSurge;
