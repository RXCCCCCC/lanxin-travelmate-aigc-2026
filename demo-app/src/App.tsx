import { useMemo, useState } from 'react';
import { demoSteps } from './data/demoFlow';

function App() {
  const [activeIndex, setActiveIndex] = useState(0);
  const activeStep = demoSteps[activeIndex];

  const progressText = useMemo(() => {
    const current = String(activeIndex + 1).padStart(2, '0');
    const total = String(demoSteps.length).padStart(2, '0');
    return `${current} / ${total}`;
  }, [activeIndex]);

  const goPrev = () => setActiveIndex((index) => Math.max(index - 1, 0));
  const goNext = () => setActiveIndex((index) => Math.min(index + 1, demoSteps.length - 1));

  return (
    <main className="showcaseShell">
      <aside className="showcasePanel leftPanel" aria-label="作品展示说明">
        <p className="panelKicker">蓝心同行 · 初赛展示页</p>
        <h2>懂你的全旅程 AI 旅行搭子</h2>
        <p className="panelLead">
          用一个可控记忆、主动陪伴、2D 具身化表达的旅行 Agent，串起出行前、出行中、出行后的完整闭环。
        </p>

        <div className="panelBlock activeBlock">
          <span>当前节点</span>
          <strong>{activeStep.showcase.headline}</strong>
          <p>{activeStep.showcase.insight}</p>
        </div>

        <div className="flowRail" aria-label="Demo流程">
          {demoSteps.map((step, index) => (
            <button
              className={index === activeIndex ? 'flowStep active' : 'flowStep'}
              key={step.id}
              onClick={() => setActiveIndex(index)}
              type="button"
            >
              <span>{String(index + 1).padStart(2, '0')}</span>
              <strong>{step.nav}</strong>
            </button>
          ))}
        </div>
      </aside>

      <section className="phoneFrame" aria-label="蓝心同行 Demo 手机原型">
        <div className="statusBar">
          <span>9:41</span>
          <span>蓝心同行</span>
          <span>5G</span>
        </div>

        <nav className="stepTabs" aria-label="演示步骤">
          {demoSteps.map((step, index) => (
            <button
              className={index === activeIndex ? 'stepTab active' : 'stepTab'}
              key={step.id}
              onClick={() => setActiveIndex(index)}
              type="button"
            >
              {step.nav}
            </button>
          ))}
        </nav>

        <div className="contentCard">
          <div className="heroHeader">
            <div>
              <p className="eyebrow">{activeStep.eyebrow}</p>
              <h1>{activeStep.title}</h1>
              <p className="subtitle">{activeStep.subtitle}</p>
            </div>
            <span className="progressPill">{progressText}</span>
          </div>

          <div className={activeStep.id === 'home' ? 'heroVisual homeVisual' : 'heroVisual'}>
            <img src={activeStep.image} alt={`蓝小心${activeStep.mood}状态`} />
          </div>

          <div className="speechBubble">{activeStep.speech}</div>

          <div className="statusGrid" aria-label="蓝小心状态">
            <div>
              <span>心情</span>
              <strong>{activeStep.mood}</strong>
            </div>
            <div>
              <span>精力</span>
              <strong>{activeStep.energy}</strong>
            </div>
            <div>
              <span>默契</span>
              <strong>{activeStep.trust}</strong>
            </div>
          </div>

          <div className="tagRow">
            {activeStep.tags.map((tag) => (
              <span key={tag}>{tag}</span>
            ))}
          </div>

          <div className="infoStack">
            {activeStep.cards.map((card) => (
              <article className="infoCard" key={card.title}>
                <div>
                  <h2>{card.title}</h2>
                  <span>{card.meta}</span>
                </div>
                <p>{card.text}</p>
              </article>
            ))}
          </div>

          <div className="actionRow">
            {activeStep.actions.map((action, index) => (
              <button className={index === 0 ? 'primaryAction' : 'secondaryAction'} key={action} type="button">
                {action}
              </button>
            ))}
          </div>
        </div>

        <div className="bottomControls">
          <button disabled={activeIndex === 0} onClick={goPrev} type="button">
            上一步
          </button>
          <div className="dotRow" aria-label="当前位置">
            {demoSteps.map((step, index) => (
              <span className={index === activeIndex ? 'dot active' : 'dot'} key={step.id} />
            ))}
          </div>
          <button disabled={activeIndex === demoSteps.length - 1} onClick={goNext} type="button">
            下一步
          </button>
        </div>
      </section>

      <aside className="showcasePanel rightPanel" aria-label="PPT截图辅助说明">
        <div className="panelBlock">
          <span>大模型应用</span>
          <strong>{activeStep.showcase.model}</strong>
        </div>

        <div className="panelBlock">
          <span>PPT 使用建议</span>
          <strong>{activeStep.showcase.ppt}</strong>
        </div>

        <div className="captureGuide">
          <p>截图建议</p>
          <ul>
            <li>只截中间手机：放“产品原型设计”页。</li>
            <li>截完整展示页：放“Demo故事线/讲解页”。</li>
            <li>按 01-06 命名，方便后续插入 PPT。</li>
          </ul>
        </div>
      </aside>
    </main>
  );
}

export default App;
