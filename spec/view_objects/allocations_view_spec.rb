require "rails_helper"

describe AllocationsView do
  let(:training_provider) { build(:provider) }
  let(:another_training_provider) { build(:provider) }
  let(:accredited_body) { build(:provider) }
  let(:training_providers) { [training_provider, another_training_provider] }

  describe "#allocation_renewals" do
    subject { AllocationsView.new(training_providers: training_providers, allocations: allocations).repeat_allocation_statuses }

    context "Accrediting provider has re-requested an allocation for a training provider" do
      let(:repeat_allocation) do
        build(:allocation, :repeat, accredited_body: accredited_body, provider: training_provider, number_of_places: 1)
      end
      let(:initial_allocation) do
        build(:allocation, :initial, accredited_body: accredited_body, provider: another_training_provider, number_of_places: 3)
      end
      let(:allocations) { [repeat_allocation, initial_allocation] }

      it {
        is_expected.to eq([
          {
            training_provider_name: training_provider.provider_name,
            training_provider_code: training_provider.provider_code,
            accredited_body_code: accredited_body.provider_code,
            status: AllocationsView::Status::REQUESTED,
            status_colour: AllocationsView::Colour::GREEN,
            requested: AllocationsView::Requested::YES,
            id: repeat_allocation.id,
            request_type: AllocationsView::RequestType::REPEAT,
          },
        ])
      }
    end

    context "Accredited body has declined an allocation for a training provider" do
      let(:declined_allocation) { build(:allocation, :declined, accredited_body: accredited_body, provider: training_provider, number_of_places: 0) }
      let(:initial_allocation) do
        build(:allocation, :initial, accredited_body: accredited_body, provider: another_training_provider, number_of_places: 3)
      end
      let(:allocations) { [declined_allocation, initial_allocation] }

      it {
        is_expected.to eq([
          {
            training_provider_name: training_provider.provider_name,
            training_provider_code: training_provider.provider_code,
            accredited_body_code: accredited_body.provider_code,
            status: AllocationsView::Status::NOT_REQUESTED,
            status_colour: AllocationsView::Colour::RED,
            requested: AllocationsView::Requested::NO,
            id: declined_allocation.id,
            request_type: AllocationsView::RequestType::DECLINED,
          },
        ])
      }
    end

    context "Accredited body is yet to repeat or decline an allocation for a training provider" do
      let(:allocations) { [] }

      it {
        is_expected.to eq([
          {
            training_provider_name: training_provider.provider_name,
            training_provider_code: training_provider.provider_code,
            status: AllocationsView::Status::YET_TO_REQUEST,
            status_colour: AllocationsView::Colour::GREY,
          },
          {
            training_provider_name: another_training_provider.provider_name,
            training_provider_code: another_training_provider.provider_code,
            status: AllocationsView::Status::YET_TO_REQUEST,
            status_colour: AllocationsView::Colour::GREY,
          },
        ])
      }
    end
  end

  describe "#initial_allocations" do
    subject { AllocationsView.new(training_providers: training_providers, allocations: allocations).initial_allocation_statuses }

    context "Accredited body has requested an initial allocation for a training provider" do
      context "more than 1 place requested" do
        let(:initial_allocation) do
          build(:allocation, :initial, accredited_body: accredited_body, provider: training_provider, number_of_places: 3)
        end

        let(:repeat_allocation) do
          build(:allocation, :repeat, accredited_body: accredited_body, provider: another_training_provider, number_of_places: 4)
        end

        let(:allocations) { [initial_allocation, repeat_allocation] }

        it {
          is_expected.to eq([
            {
              training_provider_name: training_provider.provider_name,
              training_provider_code: training_provider.provider_code,
              status: "3 PLACES REQUESTED",
              status_colour: AllocationsView::Colour::GREEN,
              requested: AllocationsView::Requested::YES,
              request_type: AllocationsView::RequestType::INITIAL,
              id: initial_allocation.id,
            },
          ])
        }
      end

      context "1 place requested" do
        let(:initial_allocation) do
          build(:allocation, :initial, accredited_body: accredited_body, provider: training_provider, number_of_places: 1)
        end

        let(:allocations) { [initial_allocation] }

        it "correctly pluralizes the status" do
          expect(subject.first[:status]).to eq("1 PLACE REQUESTED")
        end
      end
    end

    context "Accredited body has not requested initial allocations for any training provider" do
      let(:repeat_allocation) do
        build(:allocation, :repeat, accredited_body: accredited_body, provider: training_provider, number_of_places: 4)
      end

      let(:allocations) { [repeat_allocation] }

      it { is_expected.to be_empty }
    end
  end

  context "allocations are confirmed" do
    describe "#confirmed_allocation_places" do
      subject { AllocationsView.new(training_providers: training_providers, allocations: allocations).confirmed_allocation_places }

      context "returns confirmed repeat and initial allocations with number of places" do
        let(:confirmed_repeat_allocation) do
          build(:allocation, :repeat, accredited_body: accredited_body,
                                      provider: training_provider,
                                      number_of_places: 1,
                                      confirmed_number_of_places: 3)
        end

        let(:confirmed_initial_allocation) do
          build(:allocation, :initial, accredited_body: accredited_body,
                                       provider: another_training_provider,
                                       number_of_places: 2,
                                       confirmed_number_of_places: 4)
        end

        let(:allocations) { [confirmed_repeat_allocation, confirmed_initial_allocation] }

        it {
          is_expected.to eq([{ training_provider_name: training_provider.provider_name,
                               number_of_places: confirmed_repeat_allocation.number_of_places,
                               confirmed_number_of_places: confirmed_repeat_allocation.confirmed_number_of_places },
                             { training_provider_name: another_training_provider.provider_name,
                               number_of_places: confirmed_initial_allocation.number_of_places,
                               confirmed_number_of_places: confirmed_initial_allocation.confirmed_number_of_places }])
        }
      end

      context "no confirmed declined allocations are returned" do
        let(:confirmed_declined_allocation) do
          build(:allocation, :declined, accredited_body: accredited_body, provider: training_provider, number_of_places: 0)
        end

        let(:allocations) { [confirmed_declined_allocation] }

        it {
          is_expected.to eq([])
        }
      end

      context "no allocations are returned if their status is 'YET TO REQUEST'" do
        let(:allocations) { [] }

        it {
          is_expected.to eq([])
        }
      end
    end
  end

  context "allocation period is closed" do
    describe "#requested_allocations" do
      subject { AllocationsView.new(training_providers: training_providers, allocations: allocations).requested_allocations_statuses }

      context "returns allocations if their status is 'REPEATED'" do
        let(:repeat_allocation) do
          build(:allocation, :repeat, accredited_body: accredited_body, provider: training_provider, number_of_places: 1)
        end
        let(:allocations) { [repeat_allocation] }

        it {
          is_expected.to eq([{
            training_provider_name: training_provider.provider_name,
            training_provider_code: training_provider.provider_code,
            status_colour: AllocationsView::Colour::GREEN,
            status: AllocationsView::Status::REQUESTED,
          }])
        }
      end

      context "returns allocations if their status is 'INITIAL'" do
        let(:initial_allocation) do
          build(:allocation, :initial, accredited_body: accredited_body, provider: training_provider, number_of_places: 1)
        end
        let(:allocations) { [initial_allocation] }

        it {
          is_expected.to eq([{
            training_provider_name: training_provider.provider_name,
            training_provider_code: training_provider.provider_code,
            status_colour: AllocationsView::Colour::GREEN,
            status: AllocationsView::Status::REQUESTED,
          }])
        }

        it "does not display number of requested places in the status" do
          expect(subject.first[:status]).to eq("REQUESTED")
        end
      end

      context "no allocations are returned if their status is 'DECLINED' " do
        let(:declined_allocation) do
          build(:allocation, :declined, accredited_body: accredited_body, provider: training_provider, number_of_places: 0)
        end
        let(:training_providers) { [training_provider] }
        let(:allocations) { [declined_allocation] }

        it {
          is_expected.to eq([])
        }
      end

      context "no allocations are returned if their status is 'YET TO REQUEST' " do
        let(:training_providers) { [training_provider] }
        let(:allocations) { [] }

        it {
          is_expected.to eq([])
        }
      end

      describe "allocation ordering" do
        let(:initial_allocation) do
          training_provider.provider_name = "Training Provider A"
          build(:allocation, :initial, accredited_body: accredited_body, provider: training_provider, number_of_places: 1)
        end
        let(:repeat_allocation) do
          another_training_provider.provider_name = "Training Provider B"
          build(:allocation, :repeat, accredited_body: accredited_body, provider: another_training_provider, number_of_places: 0)
        end

        let(:allocations) { [initial_allocation, repeat_allocation] }

        it "is sorted by the provider name" do
          expect(subject).to eq([{ training_provider_name: training_provider.provider_name,
                                   training_provider_code: training_provider.provider_code,
                                   status_colour: AllocationsView::Colour::GREEN,
                                   status: AllocationsView::Status::REQUESTED },
                                 { training_provider_name: another_training_provider.provider_name,
                                   training_provider_code: another_training_provider.provider_code,
                                   status_colour: AllocationsView::Colour::GREEN,
                                   status: AllocationsView::Status::REQUESTED }])
        end

        it "does not display number of requested places in the status" do
          expect(subject.first[:status]).to eq("REQUESTED")
        end
      end
    end

    describe "#not_requested_allocations" do
      subject { AllocationsView.new(training_providers: training_providers, allocations: allocations).not_requested_allocations_statuses }

      context "returns allocations where status is 'NOT REQUESTED'" do
        let(:declined_allocation) { build(:allocation, :declined, accredited_body: accredited_body, provider: training_provider, number_of_places: 0) }

        let(:training_providers) { [training_provider] }

        let(:allocations) { [declined_allocation] }

        it {
          is_expected.to eq([{
            training_provider_name: training_provider.provider_name,
            training_provider_code: training_provider.provider_code,
            status: AllocationsView::Status::NOT_REQUESTED,
            status_colour: AllocationsView::Colour::RED,
          }])
        }
      end

      context "returns allocations where status is 'YET TO REQUEST'" do
        let(:allocations) { [] }

        let(:training_providers) { [training_provider] }

        it {
          is_expected.to eq([{
            training_provider_name: training_provider.provider_name,
            training_provider_code: training_provider.provider_code,
            status: AllocationsView::Status::NO_REQUEST_SENT,
            status_colour: AllocationsView::Colour::GREY,
          }])
        }
      end

      context "no allocations are returned if their status is 'REQUESTED" do
        let(:repeat_allocation) do
          build(:allocation, :repeat, accredited_body: accredited_body, provider: training_provider, number_of_places: 1)
        end

        let(:allocations) { [repeat_allocation] }

        let(:training_providers) { [training_provider] }

        it {
          is_expected.to eq([])
        }
      end

      context "no allocations are returned if their status is 'INITIAL'" do
        let(:initial_allocation) do
          build(:allocation, :initial, accredited_body: accredited_body, provider: training_provider, number_of_places: 1)
        end

        let(:allocations) { [initial_allocation] }

        let(:training_providers) { [training_provider] }

        it {
          is_expected.to eq([])
        }
      end

      describe "allocation ordering" do
        before do
          training_provider.provider_name = "Training Provider A"
          another_training_provider.provider_name = "Training Provider B"
        end

        let(:allocations) { [] }

        it "is sorted by the provider name" do
          expect(subject).to eq([{ training_provider_name: training_provider.provider_name,
                                   training_provider_code: training_provider.provider_code,
                                   status: AllocationsView::Status::NO_REQUEST_SENT,
                                   status_colour: AllocationsView::Colour::GREY },
                                 {
                                   training_provider_name: another_training_provider.provider_name,
                                   training_provider_code: another_training_provider.provider_code,
                                   status: AllocationsView::Status::NO_REQUEST_SENT,
                                   status_colour: AllocationsView::Colour::GREY,
                                 }])
        end
      end
    end
  end
end
