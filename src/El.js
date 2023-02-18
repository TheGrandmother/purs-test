import { el } from '@elemaudio/core';
import WebRenderer from '@elemaudio/web-renderer';

export const createCore = new WebRenderer()
export const createCtx = new AudioContext()
export const onCoreLoad = core => fn => () => core.on('load', () => fn(core))
export const flerp = core => () => core.render(el.cycle(440), el.cycle(441))

export const play = core => ctx => {
  (async function main() {
    ctx.resume()
    let node = await core.initialize(ctx, {
      numberOfInputs: 0,
      numberOfOutputs: 1,
      outputChannelCount: [2],
    });
    node.connect(ctx.destination);
  })()
  return core
}
