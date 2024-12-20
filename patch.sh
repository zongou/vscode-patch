#!/bin/sh
set -eu

js="workbench.js"
html="workbench.html"

## Backup files before modifying
for f in "${js}" "${html}"; do
    if ! test -f $f.bak; then
        cp $f $f.bak
    fi
done

cp "${js}".bak "${js}"

## Fix keyboard popping up when scrolling
## (zs.Contextmenu,l.initialTarget)
EventType=$(grep -Eo '\(\w+.Contextmenu,\w+\.initialTarget\)' "${js}" | grep -Eo '\w+\.Contextmenu' | cut -d'.' -f1)
var=eventType
echo EventType="${EventType}"

## ;this.F(e,m,s,Math.abs(g)/f,g>0?1:-1,u,Math.abs(p)/f,p>0?1:-1,d),this.xxx=zs.Change}this.D(this.C(zs.End,l.initialTarget)),delete this.r[a.identifier]}this.h&&(this.xxx!==zs.Change&&t.preventDefault(),this.xxx=void 0,t.stopPropagation(),this.h=!1)}
sed -E -i "s^(;this.\\w\\(e,m,s,Math.abs\\(g\\)/f,g>0\\?1:-1,u,Math.abs\\(p\\)/f,p>0\\?1:-1,d\\))^\1,this.${var}=${EventType}.Change^g" "${js}"
sed -E -i "s^(\\[a\\.identifier\\]\\}this.h&&\\()(\\w.preventDefault\\(\\),)^\\1this.${var}!==${EventType}.Change\\&\\&\\2this.${var}=void 0,^g" "${js}"
grep -E -o ';this.\w\(e,m,s,Math.abs\(g\)/f,g>0\?1:-1,u,Math.abs\(p\)/f,p>0\?1:-1,d\),this.eventType=\w+.Change\}this.\w\(this.\w+\(\w+.End,l.initialTarget\)\),delete this.\w\[\w.identifier\]\}this.\w&&\(this.eventType!==\w+.\Change&&t.preventDefault\(\),this.eventType=void 0,\w.stopPropagation\(\),this.\w=!1\)\}' "${js}"

## Mobile prefered style
## <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no, interactive-widget=resizes-content">
sed -E -i "s/(<meta name=\"viewport\" )(content=.+)(>$)/\1content=\"width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no, interactive-widget=resizes-content\"\3/" "${html}"
grep -E -o '(<meta name="viewport" )(content=.+)(>$)' "${html}"
sed -E -i "s^(Math.min\\(this\\.\\w\\.width\*)(\\.[0-9]+)^\\1.80^" "${js}"
grep -E -o '(Math.min\(this\.\w\.width\*)(\.[0-9]+)' "${js}"

## Fix context menu for android
## ,$dt=!!(hw&&hw.indexOf("Android")>=0),
isAndroid=$(grep -Eo ',.{1,5}=!!\(\w+&&\w+.\.indexOf\(\"Android\"\)>=0\)' "${js}" | cut -d= -f1 | sed s/,//)
echo isAndroid="${isAndroid}"

## (this.j.canRelayout===!1&&!(Il&&hg.pointerEvents)&&!$dt){this.hide()
sed -E -i "s^(if\\(this\\.\\w\\.canRelayout===!1&&!\\(\\w+&&\\w+\\.pointerEvents\\))(\\))^\1\&\&!${isAndroid}\2^" "${js}"
grep -E -o '\(this.\w.canRelayout===!1&&!\(\w+&&\w+.pointerEvents\)&&!.{1,5}\)\{this.hide\(\)' "${js}"

## {this.$&&!(Il&&hg.pointerEvents)&&!$dt&&this.$.blur()}
sed -E -i "s^(\\{this\\.\\$&&\\!\\(Il&&hg\\.pointerEvents\\))(&&this\\.\\$\\.blur\\(\\)\\})^\1\&\&!${isAndroid}\2^" "${js}"
grep -E -o '\(\)=>\{this\..{1,3}!\(\w+&&\w+\.pointerEvents\)&&.+\.blur\(\)' "${js}"

## showContextView(e,t,s){let n;$dt?this.b.setContainer(this.c.activeContainer,1):(t?t===this.c.getContainer(Ie(t))?n=1:s?n=3:n=2:n=1,this.b.setContainer(t??this.c.activeContainer,n)),this.b.show(e);
sed -E -i "s^(showContextView\\(\w,\w,\w\\)\\{let \w;)(.+)(,this.b.show\\(\\w\\))^\\1${isAndroid}?this.b.setContainer(this.c.activeContainer,1):(\\2)\\3^" "${js}"
grep -E -o 'showContextView\(\w,\w,\w\)\{let \w;.+this\.\w\.show\(\w\).' "${js}"

## Android keyboard
## ,properties:{"keyboard.dispatch":{scope:1,type:"string",enum:["code","keyCode"],default:$dt?"keyCode":"code",
sed -E -i "s^(,properties:\\{\"keyboard\\.dispatch\":\\{scope:1,type:\"string\",enum:\\[\"code\",\"keyCode\"\\],default:)(\"code\")^\\1${isAndroid}?\"keyCode\":\"code\"^" "${js}"
grep -E -o ',properties:\{"keyboard\.dispatch":\{scope:1,type:"string",enum:\["code","keyCode"\],default:.{1,20},' "${js}"
