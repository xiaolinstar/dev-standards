import { promisifyAll } from 'miniprogram-api-promise';

const wxp = {} as WechatMiniprogram.Wx;
promisifyAll(wx, wxp);
(globalThis as unknown as { wxp: typeof wxp }).wxp = wxp;

App({
  onLaunch() {
    // init: restore session, sync config — see skills/wechat-mp
  },
});
