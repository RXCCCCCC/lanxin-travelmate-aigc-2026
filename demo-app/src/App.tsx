import { useEffect, useMemo, useState } from 'react';
import { demoSteps, type DemoStep } from './data/demoFlow';
import imageManifest from './data/imageManifest.json';

const STORAGE_KEY = 'lanxin-travelmate-demo-steps';

function cloneSteps(steps: DemoStep[]) {
  return steps.map((step) => ({
    ...step,
    tags: [...step.tags],
    actions: [...step.actions],
    cards: step.cards.map((card) => ({ ...card })),
    showcase: { ...step.showcase },
  }));
}

function getDefaultSteps() {
  return cloneSteps(demoSteps);
}

function parseLines(value: string) {
  return value
    .split('\n')
    .map((item) => item.trim())
    .filter(Boolean);
}

function App() {
  const [steps, setSteps] = useState<DemoStep[]>(() => {
    if (typeof window === 'undefined') {
      return getDefaultSteps();
    }

    const cached = window.localStorage.getItem(STORAGE_KEY);
    if (!cached) {
      return getDefaultSteps();
    }

    try {
      const parsed = JSON.parse(cached) as DemoStep[];
      return Array.isArray(parsed) && parsed.length > 0 ? parsed : getDefaultSteps();
    } catch {
      return getDefaultSteps();
    }
  });
  const [activeIndex, setActiveIndex] = useState(0);
  const [editorMode, setEditorMode] = useState(false);

  const activeStep = steps[activeIndex] ?? steps[0];

  useEffect(() => {
    window.localStorage.setItem(STORAGE_KEY, JSON.stringify(steps));
  }, [steps]);

  const progressText = useMemo(() => {
    const current = String(activeIndex + 1).padStart(2, '0');
    const total = String(steps.length).padStart(2, '0');
    return `${current} / ${total}`;
  }, [activeIndex, steps.length]);

  const goPrev = () => setActiveIndex((index) => Math.max(index - 1, 0));
  const goNext = () => setActiveIndex((index) => Math.min(index + 1, steps.length - 1));

  const updateStepField = <K extends keyof DemoStep>(field: K, value: DemoStep[K]) => {
    setSteps((current) =>
      current.map((step, index) => (index === activeIndex ? { ...step, [field]: value } : step)),
    );
  };

  const updateShowcaseField = <K extends keyof DemoStep['showcase']>(field: K, value: DemoStep['showcase'][K]) => {
    setSteps((current) =>
      current.map((step, index) =>
        index === activeIndex
          ? {
              ...step,
              showcase: {
                ...step.showcase,
                [field]: value,
              },
            }
          : step,
      ),
    );
  };

  const updateCardField = <K extends keyof DemoStep['cards'][number]>(
    cardIndex: number,
    field: K,
    value: DemoStep['cards'][number][K],
  ) => {
    setSteps((current) =>
      current.map((step, index) => {
        if (index !== activeIndex) {
          return step;
        }

        return {
          ...step,
          cards: step.cards.map((card, currentCardIndex) =>
            currentCardIndex === cardIndex ? { ...card, [field]: value } : card,
          ),
        };
      }),
    );
  };

  const addCard = () => {
    updateStepField('cards', [
      ...activeStep.cards,
      { title: '新卡片标题', meta: '补充说明', text: '这里可以填写新的展示内容。' },
    ]);
  };

  const removeCard = (cardIndex: number) => {
    updateStepField(
      'cards',
      activeStep.cards.filter((_, index) => index !== cardIndex),
    );
  };

  const exportConfig = () => {
    const blob = new Blob([JSON.stringify(steps, null, 2)], { type: 'application/json' });
    const url = window.URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = 'lanxin-travelmate-demo.json';
    link.click();
    window.URL.revokeObjectURL(url);
  };

  const resetConfig = () => {
    const confirmed = window.confirm('确定恢复为默认展示内容吗？当前页面内修改会被清空。');
    if (!confirmed) {
      return;
    }

    const defaults = getDefaultSteps();
    setSteps(defaults);
    window.localStorage.removeItem(STORAGE_KEY);
  };

  if (!activeStep) {
    return null;
  }

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
          {steps.map((step, index) => (
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
          {steps.map((step, index) => (
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
              <article className="infoCard" key={`${card.title}-${card.meta}`}>
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
            {steps.map((step, index) => (
              <span className={index === activeIndex ? 'dot active' : 'dot'} key={step.id} />
            ))}
          </div>
          <button disabled={activeIndex === steps.length - 1} onClick={goNext} type="button">
            下一步
          </button>
        </div>
      </section>

      <aside className="showcasePanel rightPanel" aria-label="页面编辑与PPT辅助说明">
        <div className="panelToolbar">
          <button
            className={editorMode ? 'toolbarButton active' : 'toolbarButton'}
            onClick={() => setEditorMode((value) => !value)}
            type="button"
          >
            {editorMode ? '退出编辑' : '编辑模式'}
          </button>
          <button className="toolbarButton" onClick={exportConfig} type="button">
            导出 JSON
          </button>
          <button className="toolbarButton danger" onClick={resetConfig} type="button">
            恢复默认
          </button>
        </div>

        {editorMode ? (
          <div className="editorForm">
            <div className="editorSection">
              <p className="editorTitle">当前步骤基础信息</p>
              <label className="fieldLabel">
                <span>顶部标签</span>
                <input value={activeStep.nav} onChange={(event) => updateStepField('nav', event.target.value)} />
              </label>
              <label className="fieldLabel">
                <span>英文眉标</span>
                <input value={activeStep.eyebrow} onChange={(event) => updateStepField('eyebrow', event.target.value)} />
              </label>
              <label className="fieldLabel">
                <span>主标题</span>
                <textarea rows={2} value={activeStep.title} onChange={(event) => updateStepField('title', event.target.value)} />
              </label>
              <label className="fieldLabel">
                <span>副标题</span>
                <textarea rows={3} value={activeStep.subtitle} onChange={(event) => updateStepField('subtitle', event.target.value)} />
              </label>
              <label className="fieldLabel">
                <span>图片路径</span>
                <input value={activeStep.image} onChange={(event) => updateStepField('image', event.target.value)} />
                <div className="imageHints">
                  {imageManifest.map((fileName) => {
                    const imagePath = `/img/${fileName}`;
                    const selected = activeStep.image === imagePath;
                    return (
                      <button
                        className={selected ? 'imageChip active' : 'imageChip'}
                        key={fileName}
                        onClick={() => updateStepField('image', imagePath)}
                        type="button"
                      >
                        {fileName}
                      </button>
                    );
                  })}
                </div>
              </label>
              <label className="fieldLabel">
                <span>对话气泡</span>
                <textarea rows={4} value={activeStep.speech} onChange={(event) => updateStepField('speech', event.target.value)} />
              </label>
            </div>

            <div className="editorSection inlineGrid">
              <label className="fieldLabel compactField">
                <span>心情</span>
                <input value={activeStep.mood} onChange={(event) => updateStepField('mood', event.target.value)} />
              </label>
              <label className="fieldLabel compactField">
                <span>精力</span>
                <input value={activeStep.energy} onChange={(event) => updateStepField('energy', event.target.value)} />
              </label>
              <label className="fieldLabel compactField">
                <span>默契</span>
                <input value={activeStep.trust} onChange={(event) => updateStepField('trust', event.target.value)} />
              </label>
            </div>

            <div className="editorSection inlineGridTwo">
              <label className="fieldLabel">
                <span>标签（每行一个）</span>
                <textarea
                  rows={5}
                  value={activeStep.tags.join('\n')}
                  onChange={(event) => updateStepField('tags', parseLines(event.target.value))}
                />
              </label>
              <label className="fieldLabel">
                <span>按钮（每行一个）</span>
                <textarea
                  rows={5}
                  value={activeStep.actions.join('\n')}
                  onChange={(event) => updateStepField('actions', parseLines(event.target.value))}
                />
              </label>
            </div>

            <div className="editorSection">
              <p className="editorTitle">展示说明</p>
              <label className="fieldLabel">
                <span>当前节点亮点</span>
                <textarea
                  rows={2}
                  value={activeStep.showcase.headline}
                  onChange={(event) => updateShowcaseField('headline', event.target.value)}
                />
              </label>
              <label className="fieldLabel">
                <span>节点说明</span>
                <textarea
                  rows={4}
                  value={activeStep.showcase.insight}
                  onChange={(event) => updateShowcaseField('insight', event.target.value)}
                />
              </label>
              <label className="fieldLabel">
                <span>大模型应用</span>
                <textarea
                  rows={3}
                  value={activeStep.showcase.model}
                  onChange={(event) => updateShowcaseField('model', event.target.value)}
                />
              </label>
              <label className="fieldLabel">
                <span>PPT 使用建议</span>
                <textarea
                  rows={3}
                  value={activeStep.showcase.ppt}
                  onChange={(event) => updateShowcaseField('ppt', event.target.value)}
                />
              </label>
            </div>

            <div className="editorSection">
              <div className="editorSectionHeader">
                <p className="editorTitle">卡片内容</p>
                <button className="miniButton" onClick={addCard} type="button">
                  新增卡片
                </button>
              </div>

              <div className="cardEditorStack">
                {activeStep.cards.map((card, cardIndex) => (
                  <div className="cardEditor" key={`${card.title}-${cardIndex}`}>
                    <div className="cardEditorHeader">
                      <strong>卡片 {cardIndex + 1}</strong>
                      <button className="miniButton danger" onClick={() => removeCard(cardIndex)} type="button">
                        删除
                      </button>
                    </div>
                    <label className="fieldLabel compactField">
                      <span>标题</span>
                      <input value={card.title} onChange={(event) => updateCardField(cardIndex, 'title', event.target.value)} />
                    </label>
                    <label className="fieldLabel compactField">
                      <span>Meta</span>
                      <input value={card.meta} onChange={(event) => updateCardField(cardIndex, 'meta', event.target.value)} />
                    </label>
                    <label className="fieldLabel compactField">
                      <span>正文</span>
                      <textarea rows={3} value={card.text} onChange={(event) => updateCardField(cardIndex, 'text', event.target.value)} />
                    </label>
                  </div>
                ))}
              </div>
            </div>
          </div>
        ) : (
          <>
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
          </>
        )}
      </aside>
    </main>
  );
}

export default App;
