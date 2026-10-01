# Module Authoring Guide

> Every new or substantially revised module/lab should satisfy this checklist
> before merge. It exists because of a real incident: Module 2's original
> "Hands-On Lab" section described a fully-provisioned, auto-graded LMS
> environment that was never built anywhere in this repo — nobody caught it
> because nothing forced it to be run for real. See
> [issue #11](https://github.com/paruff/uFawkesDojo/issues/11) for the full
> audit and [PR #10](https://github.com/paruff/uFawkesDojo/pull/10) for the
> fix and the pattern this guide generalizes.
>
> This guide works *with* `Fawkes Dojo: Immersive Learning Architecture.md`,
> not instead of it — that document sets the vision and already cites real
> research for its self-directed-learning philosophy. This guide adds the
> checklist-level detail needed to actually follow that vision module by
> module, plus evidence for a few things the architecture doc doesn't cover.

## The one rule that matters most

**No lab step may be described unless it has been run, for real, against
real infrastructure, by the person or agent writing it.**

Not "should work based on the API docs." Not "here's what the environment
will provision." Run the actual command, see the actual output, paste that
output (or an accurate paraphrase of it) into the lab. If a real environment
to run it against doesn't exist yet, the lab doesn't get written yet either
— write an issue instead and link it from the module with a clear "lab
pending environment X" note. A described-but-unbuilt lab is worse than no
lab, because it looks complete during review.

## Checklist

### 1. Worked example before open-ended practice

Have learners study something already built and working before asking them
to build their own. Novices learn faster from a worked example than from
solving from scratch — cognitive load theory (Sweller) and a meta-analysis
of worked-example design (Crissman, 2006, an unpublished dissertation
reporting d ≈ 0.57; Wittwer & Renkl, 2010)
both support this. In lab terms: "here's the pre-built dashboard, here's
what each panel means" comes *before* "now build your own panel."

### 2. Theory blocks are short and interleaved, not front-loaded

The architecture doc's own Principle #2 states "maximum 5 minutes of theory
before hands-on practice." Audit your module's own section-time table
against this before merge — Module 2's original draft claimed this
principle while actually running 40 minutes of theory before a 20-minute
lab. Saying it doesn't make it true; the section timings have to add up to
it.

### 3. Task-first, not a feature tour

Teach only what's needed to complete a real, specific task. Don't walk
through every button in a UI "just in case" — minimalist, task-oriented
instruction beats systematic feature tours for adult learners in software
(Carroll, *The Nürnberg Funnel*, 1990). If a feature isn't used in the
lab's task, it doesn't need a paragraph in the module.

### 4. At least one open-response retrieval question, not just recognition

Multiple-choice quizzes test recognition. Recall is a stronger predictor of
retention (Roediger & Karpicke, 2006, "the testing effect") — include at
least one question per module the learner has to answer in their own words
without looking back at the material, even if it isn't auto-gradable.

### 5. Long modules get an explicit spacing boundary

Distributed practice beats massed practice (Cepeda et al., 2006
meta-analysis). If a module runs longer than ~90 minutes (Brown Belt
Module 13 runs 3–4 hours), split it into named sub-sessions with an
explicit "stop here, come back tomorrow" boundary rather than assuming
learners will do it in one sitting because it's presented as one module.

### 6. Feedback has to be immediate, not theoretical

"Auto-graded" only counts if the auto-grader actually exists and runs in
under a few minutes. If it doesn't exist yet (check the architecture doc's
Phase 1 roadmap — as of this writing, it doesn't, for anything), the lab's
feedback loop has to come from something that's real today: a script's
exit code, a dashboard panel changing, an HTTP response. Bloom's
mastery-learning research (1984) and work on immediate feedback in
intelligent tutoring (Corbett & Anderson, 1991) both point to the same
thing: feedback measured in months (or "eventually, when the LMS is
built") isn't feedback.

### 7. Badges support competence, they don't replace it

Digital badges and certification exams are fine as a visible progress
marker, but they shouldn't become the primary motivator, per
self-determination theory (Deci & Ryan) — autonomy and competence drive
intrinsic motivation better than extrinsic rewards alone. Where possible,
prefer "build/operate something real end-to-end" (a capstone) over a large
written exam, especially at Green Belt and above, where "Production-First
Learning" (Principle #1) is supposed to be the point.

### 8. Currency check

Before merging, grep the module for facts that might have moved on:

- Tool/vendor names (e.g. Jenkins → Tekton — see issue #11)
- Metric definitions (e.g. DORA's four keys → five, added late 2025)
- Contact info and URLs (e.g. `fawkes.io` → `ufawkes.dev` for email — see
  issue #11 and PR #12)
- "Last Updated" / version footer, if the module has one — bump it

### 9. Retrieval is cumulative and spaced across modules

Item 4 puts a recall question in each module; this item spaces them out.
Open every module with two or three recall questions from earlier modules,
not only the current one. Practice testing beats restudying (g = 0.51) and
beats no activity by more (g = 0.93) (Adesope, Trevisan & Sundararajan,
2017, a meta-analysis of 217 studies). Dunlosky et al. (2013) rate practice
testing and distributed practice the two highest-utility study techniques.
*Make It Stick* (Brown, Roediger & McDaniel, 2014) is the readable summary
of this research. Point learners to it.

### 10. Later belts interleave; early belts block

Mixing problem types in practice beats practising one type at a time on
delayed tests (Rohrer & Taylor, 2007), because learners have to choose the
right approach, not just repeat it. White and Yellow Belt can practise one
tool at a time. From Green Belt on, mix them: a lab that has to decide
whether a failure is a pipeline, observability or deployment problem
teaches more than three single-tool labs.

### 11. Fade the worked examples as belts advance

Item 1's worked examples help novices and can hinder experienced learners
(the expertise-reversal effect; Kalyuga, Ayres, Chandler & Sweller, 2003).
Fade them: full worked example at White Belt, a partly completed one at
Yellow and Green (the learner finishes it), and open problems at Brown and
Black. The belt ladder is what makes this fading possible, so use it.

### 12. Calibrate: predict, then measure

Learners are poor judges of what they know. Fluent re-reading feels like
learning (*Make It Stick*, ch. 5, "Avoid Illusions of Knowing"). Before a
lab, ask learners to predict the result or the time it will take; after
it, have them compare. The platform has a ready example: experienced
developers using AI were measured 19% slower while believing they were 20%
faster (METR, 2025). Use that to teach measuring, not assuming.

### 13. Support self-regulation, because the Dojo is self-paced

Self-paced online courses lose most learners. In MIT and Harvard MOOCs,
completion fell from 2013 to 2018, and 52% of registrants never opened the
courseware (Reich & Ruipérez-Valiente, 2019). In online courses, time
management, metacognition and effort regulation predict achievement
(Broadbent & Poon, 2015). Each module therefore states:

- a time estimate per sub-session (it pairs with item 5's boundaries)
- a "plan your sessions" prompt at the start of each belt
- visible progress: what's done and what's next

Belts themselves are mastery learning, which has strong support: across
108 controlled evaluations, mastery programs raised exam performance with
lasting effects, most for weaker learners (Kulik, Kulik & Bangert-Drowns,
1990). Badges add a small extra (gamification meta-analysis: g = 0.25–0.49;
Sailer & Homner, 2020), which is why item 7 keeps them secondary.

### Sources for items 9–13

- Adesope, O. O., Trevisan, D. A., & Sundararajan, N. (2017). Rethinking
  the use of tests. *Review of Educational Research*, 87(3), 659–701.
  https://eric.ed.gov/?id=EJ1141817
- Broadbent, J., & Poon, W. L. (2015). Self-regulated learning strategies
  and academic achievement in online higher education. *The Internet and
  Higher Education*, 27, 1–13.
- Brown, P. C., Roediger, H. L., & McDaniel, M. A. (2014). *Make It Stick:
  The Science of Successful Learning*. Harvard University Press.
- Dunlosky, J., et al. (2013). Improving students' learning with effective
  learning techniques. *Psychological Science in the Public Interest*,
  14(1), 4–58.
- Kalyuga, S., Ayres, P., Chandler, P., & Sweller, J. (2003). The
  expertise reversal effect. *Educational Psychologist*, 38(1), 23–31.
- Kulik, C.-L. C., Kulik, J. A., & Bangert-Drowns, R. L. (1990).
  Effectiveness of mastery learning programs. *Review of Educational
  Research*, 60(2), 265–299.
- METR (2025). Measuring the impact of early-2025 AI on experienced
  open-source developer productivity.
  https://metr.org/blog/2025-07-10-early-2025-ai-experienced-os-dev-study/
- Reich, J., & Ruipérez-Valiente, J. A. (2019). The MOOC pivot. *Science*,
  363(6423), 130–131. https://www.science.org/doi/10.1126/science.aav7958
- Rohrer, D., & Taylor, K. (2007). The shuffling of mathematics problems
  improves learning. *Instructional Science*, 35, 481–498.
- Sailer, M., & Homner, L. (2020). The gamification of learning: A
  meta-analysis. *Educational Psychology Review*, 32, 77–112.
  https://eric.ed.gov/?id=EJ1245270

## What this guide does not cover

It doesn't replace domain review (is the Kubernetes/Tekton/GitOps content
technically correct?) or accessibility review (see
`assessments/green brown black exams.md` for the existing accommodations
policy). It's specifically about whether the *learning design* is sound —
whether someone who follows this module start to finish will actually
learn and retain the thing it claims to teach.
