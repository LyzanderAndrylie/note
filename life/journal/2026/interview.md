# Interview Preparation

## General Questions

### 1. Tell me about yourself.

Hello, my name is Lyzander, and I’m a Computer Science graduate from Universitas Indonesia with a GPA of 3.96, specializing in Software Engineering and Artificial Intelligence.

I have experience as an AI Engineer at Meeting.ai, where I worked on real-time AI-powered transcription systems, large language model evaluation, and document generation pipelines. Previously, I conducted research on AI interpretability. The work is currently under review at a top journal and publicly available as an arXiv preprint, and I also co-authored a paper published at a top conference.

I’m particularly interested in full stack engineering and artificial intelligence. My long-term goal is to build reliable AI systems by combining research depth with production-level engineering.

### 2. Tell me more about your goal.

To build reliable AI systems like Google Gemini and OpenAI’s ChatGPT, I believe it is essential to have experience in both research and industry. From a research perspective, developing an AI model is not just about implementing existing methods; it involves synthesizing ideas from various research papers and innovating creative, experimental approaches that push the boundaries of current capabilities. From an industry perspective, making a system production-ready requires a deep understanding of scalability, efficiency, reliability, and user delivery. By combining both worlds, I aim to develop a holistic understanding of AI systems and build a sustainable competitive advantage in the long term.

### 3. What is your biggest strength?

My biggest strength is the combination of research depth, engineering execution, and eagerness to learn.

During my research, I proposed a novel method for detecting language-specific features in multilingual LLMs. I spent six months experimenting, analyzing, and synthesizing the results into a well-written paper. This experience trained me to think rigorously, validate hypotheses carefully, and communicate complex ideas clearly. Later, at Meeting.ai, I applied the same analytical rigor to evaluate AI systems in multilingual settings.

Beyond research, I also have experience building scalable systems. One notable project at Meeting.ai was improving the PDF generation pipeline. I identified that the previous PDF output was not optimal in terms of design and usability, so I proactively proposed improvements to both the visual design and the technical implementation. After presenting a clear plan, the solution was approved and successfully deployed to production.

I’m also a lifelong learner who enjoys exploring new technologies and continuously improving myself. I consistently strive to become a better version of myself, both technically and professionally.

### 4. What are your weaknesses?

One of my weaknesses is prioritization. I enjoy learning new technologies, especially in AI and programming, so sometimes I find it difficult to decide which one to focus on first. Since time is limited, I’ve realized that I need to prioritize what has the biggest impact. However, what is immediately useful for my career does not always fully align with my long-term goal of becoming an AI specialist. For example, improving my general programming skills can help my career, while deepening my AI expertise is also important for my long-term direction.

To improve, I now plan my learning more strategically by setting clear goals and allocating time dedicated to both, so I can make steady progress without neglecting either.

Another weakness is that I can be quite a perfectionist. I like my work to meet high standards, but sometimes this slows me down. I’m learning to balance quality and efficiency by defining clear “done” criteria for each task and reminding myself that consistent progress is better than chasing perfection.

### 5. Tell me about a challenge you faced.

When I was at Meeting.ai, I was asked to evaluate the performance of our AI system in production after an architectural change. At first, it was challenging because I wasn’t sure which metrics were the most important to evaluate.

To address this, I proactively reviewed the monitoring dashboards and took the initiative to reach out to senior engineers to clarify which metrics best reflected model performance and quality. After that, I conducted a structured comparison between the system before and after the change.

In the end, I delivered a clear evaluation report that helped the team understand the impact of the new architecture.

### 6. Tell me about a project where you led a team.

During my Software Engineering Project course, I led a team to develop a prize-based questionnaire web application. We followed the Scrum methodology and worked across four 3-week sprints.

In this project, I acted as the Product Owner. I was responsible for managing and prioritizing the product backlog, defining user stories, and ensuring the team clearly understood the requirements. I also coordinated sprint planning, reviewed progress regularly using a project management tool, and made sure we stayed aligned with the project goals.

As a result, we successfully delivered the application on time, allowing the team to maintain clear communication and structured development throughout the project.

### 7. Elaborate your research.

My research is about understanding how multilingual AI models internally represent different languages.

Most large language models can handle many languages, but we don’t clearly know how they organize this information inside. Previous research often looks at individual neurons, but single neurons usually respond to different things at once, which makes them difficult to interpret.

In my work, I used a technique called sparse autoencoders to extract clearer, more meaningful features from the model. Instead of analyzing single neurons, I analyzed learned “concept vectors” that are easier to interpret. The problem is that the number of these vectors is huge. Thus, I developed a method to identify features that are specific to one language using activation probability entropy.

From millions of learned features, I found hundreds that were strongly associated with a single language. I then showed that these features actually influence the model’s behavior, specifically its language output and performance.

In short, my research shows that multilingual AI models contain identifiable and interpretable language-specific features in the form of vectors, allowing us to systematically study and even control them.

### 8. How would your colleagues describe you?

I believe my colleagues would describe me as a hardworking, ambitious, driven, and reliable person. They would say that I set high standards for myself and consistently aim to deliver strong results. At the same time, they would recognize that I understand the importance of prioritizing and delivering impact efficiently. I strive to produce high-quality work while remaining practical, collaborative, and supportive of the team.

### 9. What motivates you?

What motivates me most is the belief that I’m capable of continuously growing and improving, just like anyone else. I’m driven by the idea of becoming a better version of myself, both technically and professionally.

In practice, that means constantly learning, refining my skills, and expanding my knowledge in software engineering and AI. I find motivation in progress, whether it’s understanding a complex concept more deeply, building a better system, or solving a challenging problem more effectively than before.

---

## Software Engineering Questions

### 10. What was your role in your previous job?

I worked as an AI Engineer at Meeting.ai, where I focused on improving and evaluating AI systems for real-time meeting transcription. Overall, my role combines model integration, evaluation, and system optimization to improve both performance and user experience.

### 11. What have you done in your previous job?

I integrated a streaming ASR model into the system, which reduced latency and improved GPU efficiency.

I also built an evaluation framework for multilingual ASR and LLM performance, developed an LLM-based typo correction prototype, and engineered a server-side PDF generation pipeline for meeting notes.

### 12. What are you most proud of in your past work?

One thing I’m most proud of is integrating a streaming-based ASR model into our transcription pipeline at Meeting.ai. After the integration, we reduced latency by around 1.5 to 2 times and improved GPU efficiency and cost performance by about 5 times. It was rewarding because the improvement wasn’t just theoretical. Simply, it had a clear, measurable impact on both system performance and operational costs. That experience made me proud because it combined technical implementation, system optimization, and real business value.

### 13. Tell me about a challenging project you worked on.

One of the most challenging projects I worked on was integrating a streaming-based ASR model into our existing system.

The challenge was that I first had to deeply understand the current architecture and codebase before making any changes. Since it was a real-time system, I needed to carefully study how the streaming pipeline worked, how Redis was used to store streaming states, and how different components communicated with each other.

I spent time reading and understanding the model code in detail to make the necessary changes safely and ensure the new model could integrate smoothly without breaking the system.

In the end, the integration was successful—we reduced latency and improved GPU efficiency while keeping the system stable. It was challenging, but it strengthened my ability to work with complex systems.

### 14. Tell me about a failure and what you learned from it.

One failure I experienced was not delivering a feature on time because I was being too perfectionistic. I spent too much time refining details and optimizing the solution before releasing the first version.

From that experience, I realized that in a fast-paced environment, delivering a working version early is often more valuable than trying to make everything perfect from the start. A solid proof of concept allows the team to gather feedback, iterate, and improve more effectively.

Since then, I’ve learned to prioritize progress over perfection—focusing on delivering impact quickly, then refining based on real feedback.

### 15. Why did you leave your previous job?

I really valued my experience as an AI engineer, especially working on applied AI systems in production. However, over time, I realized that my long-term goal is to go deeper into building and understanding AI models at a more fundamental level.

In many AI engineering roles, the focus is on integrating and fine-tuning existing models for products. Why? Because training models from scratch is resource-intensive and requires strong theoretical knowledge. Thus, that kind of deep, research-focused work is less common in typical product-driven roles.

Because of that, I decided to focus on strengthening my fundamentals in software engineering and move toward a more research-oriented path, including preparing for a master’s and potentially a PhD in the future.

### 16. Describe the production system you built.

One production system I built end-to-end was a server-side PDF generation pipeline for meeting notes.

I designed the architecture, evaluated different tools based on performance and resource usage, and implemented full integration with our backend. We used an existing typesetting system, but I built a fully customizable PDF layout on top of it to ensure flexibility and professional formatting.

One interesting challenge was memory efficiency. The system used only around 50 MB of RAM per process, and I implemented workers specifically to limit and control memory usage. This was interesting because workers are usually used to handle CPU-heavy tasks, but in this case, I used them primarily to isolate and manage RAM consumption more safely in production.

As a result, we delivered customizable, well-formatted PDFs while keeping the system stable and resource-efficient.

### 17. How do you ensure code quality?

To ensure code quality, I first ensure I clearly understand the requirements from the PRD or RFC and design a clean high-level structure before coding.

While implementing, I focus on writing modular and well-organized code. I also think carefully about what should be abstracted or reused, and which design principles or patterns are appropriate for the specific case.

I regularly review and refactor my code to keep it readable and maintainable. For me, good code is not only functional but also clean, structured, and easy for others to understand and extend.

### 18. How do you debug issues in a system?

When debugging issues, I first try to reproduce the problem locally. I use a debugger or log statements to understand the program flow and find where things go wrong.

For production issues, I check monitoring and logging tools. I use Grafana and Prometheus to look at metrics like latency and error rates, and I review logs in Kibana to track what happened.

I usually narrow down the issue step by step, focusing on data rather than assumptions.

I also use modern AI tools like Cursor to help analyze code and speed up debugging while still carefully verifying the results.

### 19. How do you evaluate whether a system is performing well?

I evaluate whether a system is performing well by relying on data-driven metrics rather than assumptions.

First, I define clear success criteria, such as latency, error rate, throughput, and resource usage. These metrics serve as the baseline for monitoring to ensure the system remains stable and consistently meets its performance targets.

For performance testing, I use scripts and tools like k6 to simulate realistic traffic and evaluate how the system behaves under load.

Overall, I focus on measurable indicators to verify that the system meets both technical performance standards and business requirements.

### 20. Describe your cloud experience.

I have hands-on experience with AWS and cloud infrastructure. I’m an AWS Certified Cloud Practitioner, which gave me a solid understanding of core AWS services and cloud fundamentals.

For a cloud computing project, I developed a temporary file storage web application using Nuxt for the frontend and Fiber for the backend. I designed and deployed the infrastructure on AWS using Terraform, which included provisioning services and managing resources through infrastructure as code.

Through that project, I gained practical experience in cloud architecture design, deployment, and managing resources in a scalable and structured way.

### 21. Tell me about a time you handled ambiguity.

One time I handled ambiguity was when I built a proof-of-concept LLM-based typo detection and correction system for meeting notes.

At the beginning, the requirements were quite vague. The CEO had a general idea of improving note quality, but there wasn’t a clear definition of what “good” looked like or how the system should behave.

To handle this, I proactively clarified expectations by asking specific questions about the desired outcome and success criteria. Instead of over-engineering the solution, I quickly built a simple web-based POC to demonstrate my proposed approach and make the idea more concrete.

Once the prototype was reviewed, we aligned on the direction, and it was approved for further development. This experience taught me the importance of clarifying ambiguity early and using fast prototypes to drive alignment.

### 22. Tell me about a time you worked under pressure.

One time I worked under pressure was when we were asked to implement a calendar integration feature within a tight one-month deadline.

Instead of trying to build everything immediately, we focused on prioritization. We identified the most critical functionalities needed for the initial release and broke them down into clear tasks. Then, we distributed the work efficiently across the team so everyone could move in parallel.

By focusing on the core features first, we were able to deliver the integration on time. After the initial release, we continued iterating and improving the feature.

This experience taught me the importance of prioritization, teamwork, and delivering value quickly under time constraints.

### 23. How do you prioritize tasks?

I prioritize tasks by evaluating their urgency and impact. I often use the Eisenhower Matrix to categorize tasks into important vs. urgent, so I can focus first on what truly drives results rather than just reacting to what feels urgent.

For example, high-impact and time-sensitive tasks receive immediate attention, while important but less urgent tasks are scheduled appropriately. Lower-priority tasks are either delegated or handled later.

This approach helps me stay organized, avoid burnout, and ensure I’m consistently working on what creates the most value.

### 24. How do you handle disagreements in a team?

When handling disagreements in a team, I focus on open and respectful discussions. I try to understand the reasoning behind each perspective instead of defending my own ideas immediately.

I believe it’s important to stay impartial and evaluate ideas based on their value, impact, and alignment with project goals—not based on who proposed them. If someone else’s approach is better, I’m open to changing my position.

For me, the goal is not to “win” an argument, but to find the best solution for the team and the product.

### 25. Describe a time you took initiative.

One time I took initiative was with the PDF generation system for meeting notes. I noticed that the existing generated documents were not well-formatted and didn’t look professional, which affected the overall user experience.

Although improving it wasn’t initially assigned as a major task, I believe it could significantly enhance product quality. So I proposed building a better server-side PDF generation pipeline and took the lead in designing and implementing it.

While the implementation turned out to be more challenging than expected, I continued refining the system until it was production-ready.

In the end, we delivered well-formatted, customizable PDFs that enhanced the overall user experience. This experience showed me that taking initiative in small but meaningful areas can create a real impact.

### 26. How do you handle feedback?

When I receive feedback, I first try to understand it objectively and evaluate its validity. I look at what the feedback is targeting. Then, I filter and prioritize the feedback based on what would create the most improvement. If it’s valid and impactful, I take action and adjust accordingly. If something is less relevant, I still reflect on it, but I focus my energy on the changes that matter most.

Overall, I see feedback as a tool for growth rather than criticism, and I use it to continuously improve my performance.

---

## High-Impact Closing

### 27. Why do you want to work here?

I want to work here because I’m looking for an environment where I can contribute meaningfully while continuing to grow technically. I believe this company values strong engineering principles, real-world impact, and continuous improvement—all of which align with how I approach my work. I’m especially motivated by opportunities where I can solve challenging problems, build robust systems, and learn from experienced engineers.

### 28. What are you looking for in your next role?

In my next role, I’m looking for three things: technical depth, ownership, and growth.

I want to work on systems that require thoughtful design and strong fundamentals. I value having ownership over projects, where I can contribute from design to production. I’m looking for an environment that encourages continuous learning and high standards.

### 29. Where do you see yourself in 3–5 years?

In 3–5 years, I see myself becoming a strong and reliable engineer with deep expertise in system design and AI-related systems. I also plan to continue strengthening my theoretical foundation, potentially pursuing a master’s degree, so I can combine strong engineering execution with research understanding. Ultimately, I want to be someone who can contribute not only at the implementation level but also at the architectural and conceptual levels.

### 30. What kind of team environment do you prefer?

I prefer a team environment that is collaborative, open to discussion, and focused on continuous improvement.

I appreciate teams where ideas are evaluated based on merit, feedback is constructive, and people take ownership of their work. A culture that values both high standards and mutual respect helps me perform at my best.

### 31. Do you have any questions for us?

Yes, I do.

1. What does success look like for this role in the first six months, and how is it measured?
2. How do you support engineers in growing technically over time?

### 32. Why should we hire you?

You should hire me because I combine a strong academic foundation, hands-on AI research and engineering experience, and practical cloud and backend development skills. This mix helps me solve complex problems and build scalable, real-world solutions effectively.

---

## Miscellaneous

### 33. What did you do during your transition from your previous job to applying for a new one?

During my transition, I intentionally took time to reflect on my previous role. I evaluated what went well, what didn’t, and what I could improve moving forward. Instead of immediately jumping into the next opportunity, I wanted to gain clarity about my long-term direction and the kind of professional I want to become.

I believe many people rush into the next step without pausing to reflect. But for me, this transition period with reflection was important and valuable—it helped me better understand my strengths, areas for growth, and career goals.

At the same time, I focused on self-improvement. I implemented structured daily habits inspired by _The Miracle Morning_ to strengthen my discipline and productivity. Moreover, I continued revising my research paper for submission to a top-tier journal, and I deepened my knowledge in software engineering and artificial intelligence to better prepare myself for upcoming opportunities.

Overall, I used this transition period not as a gap but as a phase for reflection, growth, and skill development.
