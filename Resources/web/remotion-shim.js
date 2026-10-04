// Remotion client runtime shim for WebKit
(function(window) {
    let currentFrame = 0;
    let videoConfig = {
        width: 1920,
        height: 1080,
        fps: 60,
        durationInFrames: 300
    };
    const listeners = new Set();

    function setFrame(frame) {
        currentFrame = frame;
        listeners.forEach(fn => fn(frame));
    }

    function setConfig(cfg) {
        videoConfig = {
            width: cfg.width || 1920,
            height: cfg.height || 1080,
            fps: cfg.fps || 60,
            durationInFrames: cfg.durationInFrames || 300
        };
        listeners.forEach(fn => fn(currentFrame));
    }

    function useCurrentFrame() {
        const [frame, setLocalFrame] = React.useState(currentFrame);
        React.useEffect(() => {
            const update = (f) => setLocalFrame(f);
            listeners.add(update);
            return () => listeners.delete(update);
        }, []);
        return frame;
    }

    function useVideoConfig() {
        const [cfg, setCfg] = React.useState(videoConfig);
        React.useEffect(() => {
            const update = () => setCfg({ ...videoConfig });
            listeners.add(update);
            return () => listeners.delete(update);
        }, []);
        return cfg;
    }

    // Cubic bezier implementation
    function cubicBezier(x1, y1, x2, y2) {
        return function(t) {
            // Approximation for smooth easing
            const cx = 3 * x1;
            const bx = 3 * (x2 - x1) - cx;
            const ax = 1 - cx - bx;
            const cy = 3 * y1;
            const by = 3 * (y2 - y1) - cy;
            const ay = 1 - cy - by;
            return ((ay * t + by) * t + cy) * t;
        };
    }

    const Easing = {
        linear: (t) => t,
        ease: cubicBezier(0.25, 0.1, 0.25, 1.0),
        easeIn: cubicBezier(0.42, 0.0, 1.0, 1.0),
        easeOut: cubicBezier(0.0, 0.0, 0.58, 1.0),
        easeInOut: cubicBezier(0.42, 0.0, 0.58, 1.0),
        bezier: (x1, y1, x2, y2) => cubicBezier(x1, y1, x2, y2),
        out: (fn) => (t) => 1 - fn(1 - t),
        in: (fn) => fn,
        inOut: (fn) => (t) => t < 0.5 ? 0.5 * fn(t * 2) : 0.5 * (1 - fn((1 - t) * 2)) + 0.5,
    };

    function interpolate(input, inputRange, outputRange, options) {
        const opts = options || {};
        const extrapolateLeft = opts.extrapolateLeft || 'extend';
        const extrapolateRight = opts.extrapolateRight || 'extend';
        const easing = opts.easing || Easing.linear;

        if (inputRange.length !== outputRange.length || inputRange.length < 2) {
            return outputRange[0] || 0;
        }

        // Clamp or extrapolate
        if (input <= inputRange[0]) {
            if (extrapolateLeft === 'clamp') return outputRange[0];
            if (extrapolateLeft === 'identity') return input;
        }
        const lastIdx = inputRange.length - 1;
        if (input >= inputRange[lastIdx]) {
            if (extrapolateRight === 'clamp') return outputRange[lastIdx];
            if (extrapolateRight === 'identity') return input;
        }

        // Find segment
        let segment = 0;
        for (let i = 1; i < inputRange.length; i++) {
            if (input <= inputRange[i]) {
                segment = i - 1;
                break;
            }
        }

        const inMin = inputRange[segment];
        const inMax = inputRange[segment + 1];
        const outMin = outputRange[segment];
        const outMax = outputRange[segment + 1];

        const t = (input - inMin) / (inMax - inMin);
        const easedT = easing(Math.max(0, Math.min(1, t)));
        return outMin + (outMax - outMin) * easedT;
    }

    const AbsoluteFill = ({ style, children, className }) => {
        return React.createElement('div', {
            className,
            style: {
                position: 'absolute',
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                width: '100%',
                height: '100%',
                display: 'flex',
                flexDirection: 'column',
                ...style
            }
        }, children);
    };

    const Sequence = ({ from = 0, durationInFrames = Infinity, children, style, className }) => {
        const frame = useCurrentFrame();
        if (frame < from || frame >= from + durationInFrames) {
            return null;
        }
        return React.createElement('div', {
            className,
            style: {
                position: 'absolute',
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                ...style
            }
        }, children);
    };

    window.Remotion = {
        useCurrentFrame,
        useVideoConfig,
        interpolate,
        Easing,
        AbsoluteFill,
        Sequence
    };

    window.remotionPlayerAPI = {
        setFrame,
        setConfig
    };
})(window);
