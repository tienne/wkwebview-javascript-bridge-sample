# sample swift wkwebview javascript bridge 

```
WKWebview로 javascirpt bridge 하는 방식을 셈플링했습니다.

★ 웹(프론트) → 네이티브
예전에는 UIWebView에서 연동시 기존에는 URL에 스키마를 정의해서 내려받은 스킴정보를 이용해서 파싱해서 처리했었습니다.
WKWebView에서는 추가적으로 javascript bridge를 사용해서 편하게 로직 처리를 할 수 있는 방법이 있습니다. 

★ 네이티브 → 웹(프론트)
웹(프론트) → 네이티브 로 전달방식은 추가된 방식이 있지만, 
네이티브 → 웹(프론트) 로 전달/처리 방식은 기존에 자바스크립트 함수를 호출하던 1가지(evaluatejavascript) 그대로 입니다.

아래는 그 기능들에 대한 셈플링을 해봤습니다. 
```

# 설명
