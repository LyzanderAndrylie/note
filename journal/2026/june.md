# Work Retrospective

## What I have done

- Expanded the existing get securities trading account API to deliver securities trading account data for CX and cross-functional teams, enabling faster data gathering and user problem resolution via the CX dashboard.
- Developed a synchronous OCR wrapper API utilizing in-house OCR for the KYC dashboard, enabling automated data extraction from identity photos and reducing manual entries during the KYC process.
- Implemented an internal API to check Jago linking issues in the registration process, helping the CX team resolve issues faster and reducing the account team's on-call tasks.
- Assessed the RDN amendment problem and proposed possible solutions for future reference.
- Assessed and implemented a securities trading account data snapshot flow and integrated it with an internal AI compliance check service, providing information for the KYC quality check dashboard and the Data team's AI model evaluation and improvement loop.
- Built a centralized securities trading account data compiler to provide standardized data to cross-functional teams, eliminating redundant compilers built for specific data subsets and ensuring extensibility for future use cases.
- Synchronized beneficial owner data from the account team's database to the SAS (securities administration system) by implementing a backfill mechanism for existing users and a modified flow for new users, enhancing data compliance and integrity for securities trading accounts.
- Created an internal API to retrieve securities trading account information by RDN account number, unblocking the social team and streamlining their business processes.
- Refined the user personal data amendment flow by removing unnecessary logs from the account team database and auto-fixing fields, enhancing both the developer, back-office, and user experience.
- Fixed OpenTelemetry duplicated metric and trace span issues for monitoring and observability, resulting in more accurate metrics for the account team.

## What I have learned  

- Securities trading account business processes, specifically related to pre and post registration handled by the account team.
- Reading [Effective Go](https://go.dev/doc/effective_go), [The Uber Go Style Guide](https://github.com/uber-go/guide), and [gRPC Microservices in Go](https://www.manning.com/books/grpc-microservices-in-go).
- Collaborating with the account team and other teams: the QA, Data, AI, KYC, and Social teams.
- Gaining insight, discussing, and debating ideas and things with more experienced engineers.
- Watching Bibit and Stockbit academy videos to learn more about investing.

## What could be improved

- Temper my eagerness, as mentioned in the book [The Things You Can See Only When You Slow Down: How to Be Calm in a Busy World](https://www.goodreads.com/en/book/show/30780006-the-things-you-can-see-only-when-you-slow-down). Sometimes, I want to finish my tasks as soon as possible. However, I do realize that great things require not only effort, but also time to develop. So, take time to understand the underlying, real problems, carefully and thoroughly think about the possible solutions, and execute those with confidence.
- Take action with the account team. I believe there are a lot of things that can be done to streamline the account team's processes to be more efficient and effective, with the hope that this will boost our impact on the team, ourselves, and the company. As stated in the book [Atomic habits](https://www.goodreads.com/en/book/show/40121378-atomic-habits), "And I knew that if things were going to improve, I was the one responsible for making it happen." This is also true for the account team ![:grin:](https://a.slack-edge.com/production-standard-emoji-assets/16.0/google-medium/1f601.png), maybe something like:

> And we know that if things are going to improve, we are the one responsible for making it happen.
